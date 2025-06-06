#!/bin/bash
set -x
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")

LANDSCAPE_ROOT_URL="$1"
ADMIN_EMAIL="$2"
ADMIN_PASSWORD="$3"
SCRIPT_PATH="$4"
GPG_KEY_PATH="$5"
APT_LINE="$6"
SERIES="$7"

while true; do
  login_response=$(curl -skX POST "https://${LANDSCAPE_ROOT_URL}/api/v2/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  JWT=$(printf "%s" $login_response | yq -r '.token')

  if [ "${JWT:-}" != "null" ] && [ -n "${JWT:-}" ]; then
    printf 'Login successful.\n' >&2
    break
  else
    printf "Login failed.\n." >&2
    printf "Response: %s\n" "${login_response:-}" >&2
    printf "Trying again...\n." >&2
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

SET_PREFERENCES_URL="https://${LANDSCAPE_ROOT_URL}/api/v2/preferences"

rest_api_request "PATCH" "${SET_PREFERENCES_URL}" '{"auto_register_new_computers": true}'

# Create a script

EXAMPLE_CODE=$(base64 -w 0 welcome.sh)

CREATE_SCRIPT_URL="https://${LANDSCAPE_ROOT_URL}/api?action=CreateScript&version=2011-08-01&code=${EXAMPLE_CODE}&title=Welcome+Script&script_type=V2&access_group=global"

rest_api_request "GET" "${CREATE_SCRIPT_URL}"

# Create a script profile

CREATE_SCRIPT_PROFILE_URL="https://${LANDSCAPE_ROOT_URL}/api/v2/script-profiles"

body=$(
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

rest_api_request "POST" "${CREATE_SCRIPT_PROFILE_URL}" "${body}"

# Import GPG key into Landscape


KEY_NAME=$(basename "$GPG_KEY_PATH" .asc | tr -d '\n')

GPG_KEY_CONTENT=$(cat "$GPG_KEY_PATH")

IMPORT_GPG_KEY_URL="https://${LANDSCAPE_ROOT_URL}/api/?action=ImportGPGKey&version=2011-08-01&name=${KEY_NAME}&material=${GPG_KEY_CONTENT}"

rest_api_request "POST" "${IMPORT_GPG_KEY_URL}"

# Create APT Source with it

url_part=$(echo "$APT_LINE" | awk '{print $2}')

SOURCE_NAME="$(echo "$url_part" | awk -F'/' '{print $4}')-${SERIES}"

CREATE_APT_SOURCE_URL="https://${LANDSCAPE_ROOT_URL}/api/?action=CreateAPTSource&version=2011-08-01&name=${SOURCE_NAME}&apt_line=${APT_LINE}&gpg_key=${KEY_NAME}"

rest_api_request "POST" "${CREATE_APT_SOURCE_URL}"

echo '{"status": "done"}'
