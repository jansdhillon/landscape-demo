#!/bin/bash
set -x
HAPROXY_IP="$1"
ADMIN_EMAIL="$2"
ADMIN_PASSWORD="$3"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")

while true; do
  login_response=$(curl -skX POST "https://${HAPROXY_IP}/api/v2/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  JWT=$(printf "%s" $login_response | yq -r '.token')

  if [ "${JWT:-}" != "null" ] && [ -n "${JWT:-}" ]; then
    printf 'Login successful.\n'>&2
    break
  else
    printf "Login failed. Response: %s\n" "${login_response:-}" >&2
    sleep 5
  fi
done

rest_api_request() {
  local method=$1
  local url=$2
  local body=${3:-}

  response=""
  if [ -n "${body:-}" ]; then
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}" \
      -H "Content-Type: application/json" \
      -d "$body")
  else
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}")
  fi

  printf "Response:\n" >&2
  printf '%s\n' "$response" | yq >&2
}

# enable auto registration

SET_PREFERENCES_URL="https://${HAPROXY_IP}/api/v2/preferences"

rest_api_request "PATCH" "${SET_PREFERENCES_URL}" '{"auto_register_new_computers": true}'

# Create a script

EXAMPLE_CODE=$(base64 -w 0 example.sh)

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
  "title": "Welcome to Landscape",
  "trigger": {
    "trigger_type": "event",
    "event_type": "post_enrollment",
    "start_after": "${NOW}"
  },
  "username": "root"
}
EOF
)

rest_api_request "POST" "${CREATE_SCRIPT_PROFILE_URL}" "${BODY}"

echo '{"status": "done"}'
