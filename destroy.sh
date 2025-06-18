#!/bin/bash
set -euo pipefail

WORKSPACE_NAME="${1:-}"

if [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; then
    read -r -p "Enter the name of the workspace to destroy: " WORKSPACE_NAME
fi

if ! tofu workspace select "$WORKSPACE_NAME"; then
    exit
fi

if ! juju switch "$WORKSPACE_NAME"; then
    exit
fi

HAPROXY_IP=$(server/get_haproxy_ip.sh "$WORKSPACE_NAME" | yq -r ".ip_address")

tofu destroy -auto-approve -var-file terraform.tfvars.json -var "workspace_name=${WORKSPACE_NAME}"
tofu workspace select default
tofu workspace delete "$WORKSPACE_NAME"
juju destroy-model --no-prompt "$WORKSPACE_NAME" --no-wait --force

if [ -n "${HAPROXY_IP:-}" ]; then
    printf "Using 'sudo' to remove all entries for IP ${HAPROXY_IP} from /etc/hosts...\n"
    sudo sed -i "/${HAPROXY_IP}/d" /etc/hosts
fi
