#!/bin/bash

set -eE -o pipefail

cat <<EOF
@@@@@@@@@@@@@@@@@@
@@@@---@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-######-@@@@
@@@@-########-@@@@
@@@@@@@@@@@@@@@@@@

Welcome to Landscape!

EOF

LANDSCAPE_FQDN="landscape.example.com"
MODEL_NAME="landscape"
REGISTRATION_KEY="key"
# fka "series"
PPA="ppa:landscape/self-hosted-beta"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")
# Landsacpe Client units
NUM_LS_CLIENT_UNITS=3
CLIENT_BASE="ubuntu@20.04"
SERVER_BASE="ubuntu@22.04"
# Postgres units
NUM_DB_UNITS=2

while [[ -z $PRO_TOKEN ]]; do
  echo -n "'PRO_TOKEN' is not set. Visit https://ubuntu.com/pro/dashboard to get it,"
  read -r -p " and enter it here: " PRO_TOKEN
done

cleanup() {
  echo "Cleaning up model and exiting..."
  rm -rf server.pem

  if [ -n "$HAPROXY_IP" ] && [ -n "$LANDSCAPE_FQDN" ]; then
    echo "Modifying /etc/hosts requires elevated privileges."
    sudo sed -i.bak "/$HAPROXY_IP[[:space:]]\+$LANDSCAPE_FQDN/d" /etc/hosts
  fi

  juju destroy-model --no-prompt $MODEL_NAME --no-wait --force
  exit
}

trap cleanup SIGINT
trap cleanup ERR

juju add-model $MODEL_NAME

echo "Provisioning machines..."

# Add the Landscape Server unit and the other apps we need to run Landscape
# based on https://github.com/canonical/landscape-bundles/blob/scalable-stable/bundle.yaml

juju deploy ch:landscape-server \
  --config landscape_ppa="${PPA}" \
  --constraints mem=4096 \
  --base "$SERVER_BASE" \
  --config registration_key="${REGISTRATION_KEY}"

juju deploy ch:haproxy \
  --channel stable \
  --revision 75 \
  --config default_timeouts="queue 60000, connect 5000, client 120000, server 120000" \
  --config global_default_bind_options=no-tlsv10 \
  --config services="" \
  --config ssl_cert=SELFSIGNED \
  --base ubuntu@22.04

juju expose haproxy

juju deploy ch:postgresql \
  --config plugin_plpython3u_enable=true \
  --config plugin_ltree_enable=true \
  --config plugin_intarray_enable=true \
  --config plugin_debversion_enable=true \
  --config plugin_pg_trgm_enable=true \
  --config experimental_max_connections=500 \
  --channel 14/stable \
  --revision 468 \
  --base ubuntu@22.04 \
  --constraints mem=2048 \
  -n "$NUM_DB_UNITS"

juju deploy ch:rabbitmq-server \
  --channel 3.9/stable \
  --revision 188 \
  --base ubuntu@22.04 \
  --config consumer-timeout=259200000

# For Landscape Client to use in the future
juju deploy --base $CLIENT_BASE lxd -n $NUM_LS_CLIENT_UNITS

echo "Waiting for LXD units to become active..."
juju wait-for application lxd --query='(status=="active")'

echo "Attaching Ubuntu Pro token..."
for i in $(seq 0 $((NUM_LS_CLIENT_UNITS - 1))); do
  echo "Attaching token to lxd/${i}"
  juju ssh "lxd/${i}" "sudo pro attach ${PRO_TOKEN}"
done

# Next, setup the relations

juju relate landscape-server rabbitmq-server
juju relate landscape-server haproxy
juju integrate landscape-server:db postgresql:db-admin

echo "Waiting for the model to settle"
while true; do
  ls_status=$(juju status landscape-server --format=yaml | yq '.applications.landscape-server.application-status.current')
  pg_status=$(juju status postgresql --format=yaml | yq '.applications.postgresql.application-status.current')

  if [[ "$ls_status" == "active" && "$pg_status" == "active" ]]; then
    echo "done."
    break
  fi
  printf "."
  sleep 1
done

# Get the HAProxy IP

HAPROXY_IP=$(juju show-unit "haproxy/0" | yq '."haproxy/0".public-address')
echo "$HAPROXY_IP $LANDSCAPE_FQDN" | sudo tee -a /etc/hosts >/dev/null

# Get the self-signed cert
echo | openssl s_client -connect "${HAPROXY_IP}:443" | openssl x509 | sudo tee server.pem >/dev/null

# base64 encode it to use for Landscape Client units

B64_CERT=$(cat server.pem | base64)

echo "Visit https://${LANDSCAPE_FQDN} to finalize Landscape Server configuration,"
read -r -p "then press Enter to continue provisioning Landscape Client instances, or CTRL+C to exit..."

# Deploy Landscape Client

juju deploy ch:landscape-client --config account-name='standalone' \
  --config ping-url="http://${HAPROXY_IP}/ping" \
  --config url="https://${HAPROXY_IP}/message-system" \
  --config ssl-public-key="base64:${B64_CERT}" \
  --config ppa="${PPA}" \
  --config registration-key="${REGISTRATION_KEY}" \
  --config script-users="ALL" \
  --config include-manager-plugins="ScriptExecution"

# Relate it to LXD

juju relate lxd landscape-client

# Get the admin username and credentials

echo "The credentials from the first Landscape user you just created are needed to perform actions like creating scripts."

while true; do
  read -r -p "Enter the email of the user you just created: " ADMIN_EMAIL
  read -r -s -p "Enter the password: " ADMIN_PASSWORD
  echo

  RESPONSE=$(curl -skX POST "https://${LANDSCAPE_FQDN}/api/v2/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  JWT=$(echo "${RESPONSE}" | yq -r '.token')

  if [ "${JWT}" != "null" ] && [ -n "${JWT}" ]; then
    echo "Login successful\!"
    break
  else
    echo "Login failed. Try again? (y/n)"
    read -r RETRY
    if [[ "${RETRY}" != "y" && "${RETRY}" != "Y" ]]; then
      echo "Exiting."
      exit 1
    fi
  fi
done

make_rest_api_request() {
  local url=$1
  local method=$2
  local body=$3

  if [[ -n "$body" ]]; then
    RESPONSE=$(curl -skX "$method" "$url" \
      -H "Authorization: Bearer $JWT" \
      -H "Content-Type: application/json" \
      -d "$body")
  else
    RESPONSE=$(curl -skX "${method}" "$url" \
      -H "Authorization: Bearer $JWT")
  fi

  echo "Response: $RESPONSE" | yq
}

# Create a script

EXAMPLE_CODE=$(base64 <<<'#!/bin/bash
echo "Hello world!" | tee hello.txt')

CREATE_SCRIPT_URL="https://${LANDSCAPE_FQDN}/api?action=CreateScript&version=2011-08-01&code=${EXAMPLE_CODE}&title=Test+Script&script_type=V2&access_group=global"

make_rest_api_request "$CREATE_SCRIPT_URL" "GET"

# Create a script profile

CREATE_SCRIPT_PROFILE_URL="https://${LANDSCAPE_FQDN}/api/v2/script-profiles"

BODY=$(
  cat <<EOF
{
  "all_computers": true,
  "script_id": 1,
  "tags": [],
  "time_limit": 300,
  "title": "Cron",
  "trigger": {
    "trigger_type": "recurring",
    "interval": "* * * * *",
    "start_after": "$NOW"
  },
  "username": "root"
}
EOF
)

make_rest_api_request "$CREATE_SCRIPT_PROFILE_URL" "POST" "$BODY"

juju wait-for application landscape-client --query='(status=="active")'

# Manually execute the script on the Landscape Client instances

EXECUTE_SCRIPT_URL="https://${LANDSCAPE_FQDN}/api/?action=ExecuteScript&version=2011-08-01&query=id:2+OR+id:1&script_id=1&username=root&time_limit=300"

make_rest_api_request "$EXECUTE_SCRIPT_URL" "GET"

echo "Setup complete! Login at https://${LANDSCAPE_FQDN}/new_dashboard to start managing your Ubuntu fleet."
