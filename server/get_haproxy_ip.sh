#!/bin/bash
MODEL_NAME="$1"

IP_ADDRESS=""
while true; do
  IP_ADDRESS=$(juju show-unit -m "$MODEL_NAME" "haproxy/0" | yq '."haproxy/0".public-address')

  if [[ -z "${IP_ADDRESS}" || "$IP_ADDRESS" == "null" ]]; then
    printf "HAProxy unit public address not found.\n" >&2
    printf "Trying again...\n" >&2
    sleep 5
  else
    break
  fi
done

echo "{\"ip_address\": \"$IP_ADDRESS\"}"
