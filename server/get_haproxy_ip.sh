#!/bin/bash
MODEL_NAME="$1"
TIMEOUT="$2"

IP_ADDRESS=""
timeout="${TIMEOUT:-120}" # 2 minutes
start_time=$(date +%s)
while true; do
  IP_ADDRESS=$(juju show-unit -m "$MODEL_NAME" "haproxy/0" | yq '."haproxy/0".public-address')

  if [[ -z "${IP_ADDRESS}" || "$IP_ADDRESS" == "null" ]]; then
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    if (( elapsed >= timeout )); then
        printf "Timeout reached after %d seconds." "$timeout" >&2
        break
    fi
    
    printf "HAProxy unit public address not found.\n" >&2
    printf "Trying again...\n" >&2
    sleep 5
  else
    break
  fi
done

echo "{\"ip_address\": \"$IP_ADDRESS\"}"
