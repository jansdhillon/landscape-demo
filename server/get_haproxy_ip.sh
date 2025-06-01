#!/bin/bash
MODEL_NAME="$1"

IP_ADDRESS=""
while [[ -z "${IP_ADDRESS}" || "$IP_ADDRESS" == "null" ]]; do
  IP_ADDRESS=$(juju show-unit -m "$MODEL_NAME" "haproxy/0" | yq '."haproxy/0".public-address')

  if [[ -z "${IP_ADDRESS}" || "$IP_ADDRESS" == "null" ]]; then
    echo "HAProxy unit public address not found." >&2
    echo "Trying again..." >&2
    sleep 5
  else
    break
  fi
done

echo "{\"ip_address\": \"$IP_ADDRESS\"}"


