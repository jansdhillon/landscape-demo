#!/bin/bash
HAPROXY_IP="$1"
ADMIN_EMAIL="$2"
ADMIN_PASSWORD="$3"

while true; do
  login_response=$(curl -skX POST "https://${HAPROXY_IP}/api/v2/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  JWT=$(printf "%s" $login_response | yq -r '.token')

  if [ "${JWT:-}" != "null" ] && [ -n "${JWT:-}" ]; then
    printf 'Login successful.\n'
    break
  else
    printf "Login failed. Response: %s\n" "${login_response:-}"
    printf 'Trying again... (CTRL+C to abort)\n'
    sleep 5
  fi
done

echo "{\"jwt\": \"$JWT\"}"
