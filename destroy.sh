#!/bin/bash
set -euo pipefail

WORKSPACE_NAME="${1:-}"

if [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; then
    read -r -p "Enter the name of the workspace to destroy: " WORKSPACE_NAME
fi

set +e +o pipefail

tofu destroy -auto-approve -var-file terraform.tfvars.json
tofu workspace select default
tofu workspace delete "$WORKSPACE_NAME"
juju destroy-model --no-prompt "$WORKSPACE_NAME" --no-wait --force
