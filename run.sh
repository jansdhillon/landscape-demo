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
CONTROLLER_NAME="landscape-controller"
REGISTRATION_KEY="key"
# fka "series"
PPA="ppa:landscape/self-hosted-beta"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")
# Landsacpe Client units
NUM_LS_CLIENT_UNITS=1
CLIENT_BASE="ubuntu@20.04"
SERVER_BASE="ubuntu@22.04"
# Postgres units
NUM_DB_UNITS=1
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="pwd"
ADMIN_NAME="Landscape Admin"

while [[ -z $PRO_TOKEN ]]; do
  printf "'PRO_TOKEN' is not set. Visit https://ubuntu.com/pro/dashboard to get it,"
  read -r -p " and enter it here: " PRO_TOKEN
done

cleanup() {
  printf "Cleaning up model and exiting...\n"
  rm -rf server.pem

  if [ -n "${HAPROXY_IP}" ] && [ -n "${LANDSCAPE_FQDN}" ]; then
    printf "Modifying /etc/hosts requires elevated privileges.\n"
    sudo sed -i.bak "/${HAPROXY_IP}[[:space:]]\+${LANDSCAPE_FQDN}/d" /etc/hosts
  fi

  juju destroy-controller --no-prompt "${CONTROLLER_NAME}" --destroy-all-models --no-wait --force
  exit
}

trap cleanup SIGINT
trap cleanup ERR

juju bootstrap lxd "${CONTROLLER_NAME}"

juju add-model "${MODEL_NAME}"

printf "Provisioning machines...\n"

# Add the Landscape Server unit and the other apps we need to run Landscape
# based on https://github.com/canonical/landscape-bundles/blob/scalable-stable/bundle.yaml

juju deploy ch:landscape-server \
  --config landscape_ppa="${PPA}" \
  --constraints mem=4096 \
  --base "${SERVER_BASE}" \
  --config registration_key="${REGISTRATION_KEY}" \
  --config admin_name="${ADMIN_NAME}" \
  --config admin_email="${ADMIN_EMAIL}" \
  --config admin_password="${ADMIN_PASSWORD}" \
  --config min_install=true

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
  -n "${NUM_DB_UNITS}"

juju deploy ch:rabbitmq-server \
  --channel 3.9/stable \
  --revision 188 \
  --base ubuntu@22.04 \
  --config consumer-timeout=259200000

# For Landscape Client to use in the future
juju deploy --base "${CLIENT_BASE}" lxd -n "${NUM_LS_CLIENT_UNITS}"

# Next, setup the relations

juju integrate landscape-server rabbitmq-server
juju integrate landscape-server haproxy
juju integrate landscape-server:db postgresql:db-admin

printf "Waiting for the model to settle...\n"
juju wait-for model "${MODEL_NAME}" --timeout 3600s --query='forEach(units, unit => unit.workload-status == "active")'

# Get the HAProxy IP

HAPROXY_IP=$(juju show-unit "haproxy/0" | yq '."haproxy/0".public-address')
printf "%s %s" "$HAPROXY_IP" "$LANDSCAPE_FQDN" | sudo tee -a /etc/hosts >/dev/null

while true; do
  # Get the self-signed cert
  set +e
  B64_CERT=$(
    echo | openssl s_client -connect "$HAPROXY_IP:443" 2>/dev/null | openssl x509 2>/dev/null | base64
  )
  set -e

  if [ "${B64_CERT}" != "null" ] && [ -n "${B64_CERT}" ]; then
    break
  else
    printf "Failed to get certificate.\n"
    printf "Trying again... (CTRL+C to abort)\n"
    sleep 5
  fi
done

# Get the JWT
# We do this in a loop to avoid transient 503s
while true; do
  login_response=$(curl -skX POST "https://${LANDSCAPE_FQDN}/api/v2/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  JWT=$(printf "%s" $login_response | yq -r '.token')

  if [ "${JWT}" != "null" ] && [ -n "${JWT}" ]; then
    printf "Login successful\!\n"
    break
  else
    printf "Login failed. Response: %s\n" "$login_response"
    printf "Trying again... (CTRL+C to abort)\n"
    sleep 5
  fi
done

make_rest_api_request() {
  local method=$1
  local url=$2
  local body=$3

  if [[ -n "$body" ]]; then
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}" \
      -H "Content-Type: application/json" \
      -d "${body}")
  else
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}")
  fi

  printf "Response: %s\n" "$response" | yq
}

# enable auto registration

SET_PREFERENCES_URL="https://${LANDSCAPE_FQDN}/api/v2/preferences"

BODY=$(
  cat <<EOF
{
  "auto_register_new_computers": true
}
EOF
)

make_rest_api_request "PATCH" "${SET_PREFERENCES_URL}" "${BODY}"

# Create a script

EXAMPLE_CODE=$(base64 <<<'#!/bin/bash
echo "Hello world!" | tee hello.txt'
)

CREATE_SCRIPT_URL="https://${LANDSCAPE_FQDN}/api?action=CreateScript&version=2011-08-01&code=${EXAMPLE_CODE}&title=Test+Script&script_type=V2&access_group=global"

make_rest_api_request "GET" "${CREATE_SCRIPT_URL}"

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
    "start_after": "${NOW}"
  },
  "username": "root"
}
EOF
)

make_rest_api_request "POST" "${CREATE_SCRIPT_PROFILE_URL}" "${BODY}"

# Deploy Landscape Client

juju deploy ch:landscape-client --config account-name='standalone' \
  --config ping-url="http://${HAPROXY_IP}/ping" \
  --config url="https://${HAPROXY_IP}/message-system" \
  --config ssl-public-key="base64:${B64_CERT}" \
  --config ppa="${PPA}" \
  --config registration-key="${REGISTRATION_KEY}" \
  --config script-users="ALL" \
  --config include-manager-plugins="ScriptExecution"

printf "Attaching Ubuntu Pro token...\n"
for i in $(seq 0 $((NUM_LS_CLIENT_UNITS - 1))); do
  printf "Attaching token to lxd/${i}\n"
  juju ssh "lxd/${i}" "sudo pro attach ${PRO_TOKEN}"
done

juju integrate lxd landscape-client

juju wait-for model "${MODEL_NAME}" --timeout 3600s --query='forEach(units, unit => unit.workload-status == "active")'

# Manually execute the script on the Landscape Client instances

EXECUTE_SCRIPT_URL="https://${LANDSCAPE_FQDN}/api/?action=ExecuteScript&version=2011-08-01&query=id:1&script_id=1&username=root&time_limit=300"

make_rest_api_request "GET" "${EXECUTE_SCRIPT_URL}"

printf "Setup complete 🚀 \nYou can now login at https://%s/new_dashboard using the following credentials:\nEmail: %s\nPassword: %s\n" "$LANDSCAPE_FQDN" "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
