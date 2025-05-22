#!/bin/bash

read_var() {
  local var=$1
  local res

  res=$(grep "^$var=" variables.txt | cut -d'=' -f2-)

  while [[ -z $res ]]; do
    printf "'%s' is not set.\n" "$var" >&2

    if [[ "$var" == "PRO_TOKEN" ]]; then
      if [[ -n $PRO_TOKEN ]]; then
        printf "Using 'PRO_TOKEN' environment variable...\n" >&2
        res=$PRO_TOKEN
      else
        printf "Visit https://ubuntu.com/pro/dashboard to get it, then\n" >&2
      fi
    fi

    if [[ -z $res ]]; then
      read -r -p " enter it here: " res
    fi
  done

  echo -ne "${res}"
}

LANDSCAPE_FQDN=$(read_var "LANDSCAPE_FQDN")
MODEL_NAME=$(read_var "MODEL_NAME")
REGISTRATION_KEY=$(read_var "REGISTRATION_KEY")
# fka "series"
PPA=$(read_var "PPA")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")
# Landsacpe Client units
NUM_LS_CLIENT_UNITS=$(read_var "NUM_LS_CLIENT_UNITS")
CLIENT_BASE=$(read_var "CLIENT_BASE")
SERVER_BASE=$(read_var "SERVER_BASE")
# Postgres units
NUM_DB_UNITS=$(read_var "NUM_DB_UNITS")
ADMIN_EMAIL=$(read_var "ADMIN_EMAIL")
ADMIN_PASSWORD=$(read_var "ADMIN_PASSWORD")
ADMIN_NAME=$(read_var "ADMIN_NAME")
PRO_TOKEN=$(read_var "PRO_TOKEN")
MIN_INSTALL=$(read_var "MIN_INSTALL")
CRON_INTERVAL=$(read_var "CRON_INTERVAL")

BOLD="\e[1m"
ORANGE="\e[33m"
RESET_TEXT="\e[0m"

bold_orange_text() {
  local text=$1
  echo -e "${BOLD}${ORANGE}${text}${RESET_TEXT}"
}

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
EOF

bold_orange_text 'Welcome to Landscape!'

cleanup() {
  printf "Cleaning up model and exiting...\n"

  if [ -n "${HAPROXY_IP}" ]; then
    printf "Modifying /etc/hosts requires elevated privileges.\n"
    sudo sed -i "/${HAPROXY_IP}[[:space:]]\\+landscape\.example\.com/d" /etc/hosts
  fi

  juju destroy-model --no-prompt "${MODEL_NAME}" --no-wait --force
  exit
}

trap cleanup SIGINT

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
  --config min_install="${MIN_INSTALL}"

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

msg=$(bold_orange_text 'juju status --watch 2s')
printf "Waiting for the model to settle...\nUse %s in another terminal for a live view.\n" "$msg"


juju wait-for model "$MODEL_NAME" --timeout 3600s --query='forEach(units, unit => unit.workload-status == "active")'

printf "%sAttaching Ubuntu Pro token...%s\n" "$ORANGE" "$RESET_TEXT"
for i in $(seq 0 $((NUM_LS_CLIENT_UNITS - 1))); do
  printf "Attaching token to lxd/${i}\n"
  juju ssh "lxd/${i}" "sudo pro attach ${PRO_TOKEN}"
done

# Get the HAProxy IP

HAPROXY_IP=$(juju show-unit "haproxy/0" | yq '."haproxy/0".public-address')
printf "Modifying /etc/hosts requires elevated privileges.\n"
printf "%s %s\n" "$HAPROXY_IP" "$LANDSCAPE_FQDN" | sudo tee -a /etc/hosts >/dev/null

while true; do
  # Get the self-signed cert
  B64_CERT=$(
    echo | openssl s_client -connect "$HAPROXY_IP:443" 2>/dev/null | openssl x509 2>/dev/null | base64
  )

  if [ "${B64_CERT}" != "null" ] && [ -n "${B64_CERT}" ]; then
    break
  else
    printf "Failed to get certificate.\n"
    printf 'Trying again... (CTRL+C to abort)\n'
    sleep 5
  fi
done

# Get the JWT
# We do this in a loop to avoid transient 503s
while true; do
  login_response=$(curl -skX POST "https://${HAPROXY_IP}/api/v2/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  JWT=$(printf "%s" $login_response | yq -r '.token')

  if [ "${JWT}" != "null" ] && [ -n "${JWT}" ]; then
    printf 'Login successful!\n'
    break
  else
    printf "Login failed. Response: %s\n" "$login_response"
    printf 'Trying again... (CTRL+C to abort)\n'
    sleep 5
  fi
done

rest_api_request() {
  local method=$1
  local url=$2
  local body=$3

  if [[ -n "$body" ]]; then
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}" \
      -H "Content-Type: application/json" \
      -d "$body")
  else
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}")
  fi

  printf "Response: %s\n" "$response" | yq
}

# enable auto registration

SET_PREFERENCES_URL="https://${HAPROXY_IP}/api/v2/preferences"

rest_api_request "PATCH" "${SET_PREFERENCES_URL}" '{"auto_register_new_computers": true}'

# Create a script

EXAMPLE_CODE=$(base64 < example.sh)

CREATE_SCRIPT_URL="https://${HAPROXY_IP}/api?action=CreateScript&version=2011-08-01&code=${EXAMPLE_CODE}&title=Test+Script&script_type=V2&access_group=global"

rest_api_request "GET" "${CREATE_SCRIPT_URL}"

# Create a script profile

CREATE_SCRIPT_PROFILE_URL="https://${HAPROXY_IP}/api/v2/script-profiles"

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
    "interval": "${CRON_INTERVAL}",
    "start_after": "${NOW}"
  },
  "username": "root"
}
EOF
)

rest_api_request "POST" "${CREATE_SCRIPT_PROFILE_URL}" "${BODY}"

# Deploy Landscape Client

juju deploy ch:landscape-client --config account-name='standalone' \
  --config ping-url="http://${HAPROXY_IP}/ping" \
  --config url="https://${HAPROXY_IP}/message-system" \
  --config ssl-public-key="base64:${B64_CERT}" \
  --config ppa="${PPA}" \
  --config registration-key="${REGISTRATION_KEY}" \
  --config script-users="ALL" \
  --config include-manager-plugins="ScriptExecution"

juju integrate lxd landscape-client

printf "Waiting for the Landscape Clients to register\n"

juju wait-for model "$MODEL_NAME" --timeout 3600s --query='forEach(units, unit => unit.workload-status == "active")'

# Manually execute the script on the Landscape Client instances

QUERY=""

for i in $(seq 1 $NUM_LS_CLIENT_UNITS); do
  QUERY+="id:$i"
  if [[ $i -lt $NUM_LS_CLIENT_UNITS ]]; then
    QUERY+="+OR+"
  fi
done

EXECUTE_SCRIPT_URL="https://${HAPROXY_IP}/api/?action=ExecuteScript&version=2011-08-01&query=${QUERY}&script_id=1&username=root&time_limit=300"

rest_api_request "GET" "${EXECUTE_SCRIPT_URL}"

echo -e "${BOLD}Setup complete 🚀${RESET_TEXT}\nYou can now login at ${BOLD}https://${LANDSCAPE_FQDN}/new_dashboard${RESET_TEXT} using the following credentials:\n${BOLD}Email:${RESET_TEXT} ${ADMIN_EMAIL}\n${BOLD}Password:${RESET_TEXT} ${ADMIN_PASSWORD}\n"
