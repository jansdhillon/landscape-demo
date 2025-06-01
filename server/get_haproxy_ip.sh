#!/bin/bash
MODEL_NAME="$1"

IP_ADDRESS=$(juju show-unit -m "$MODEL_NAME" "haproxy/0" | yq '."haproxy/0".public-address' 2>/dev/null)

if [ -z "$IP_ADDRESS" ]; then
  IP_ADDRESS=""
  echo "Warning: HAProxy unit public address not found." >&2
fi

echo "{\"ip_address\": \"$IP_ADDRESS\"}"
