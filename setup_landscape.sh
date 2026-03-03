#!/bin/bash

LANDSCAPE_ROOT_URL="$1"
ADMIN_EMAIL="$2"
ADMIN_PASSWORD="$3"

timeout=600 # 10 minutes
start_time=$(date +%s)
while true; do
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if (( elapsed >= timeout )); then
      printf "Timeout reached after %d seconds.\n" $timeout >&2
      break
  fi

  login_response=$(curl -skX POST "https://${LANDSCAPE_ROOT_URL}/api/v2/login" \
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

echo '{"status": "done"}'
