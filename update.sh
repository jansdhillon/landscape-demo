#!/bin/bash
set -euo pipefail

source ./utils.sh

check_for_tfvars

WORKSPACE_NAME="${1:-}"
if [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; then
    read -r -p "Enter the name of the workspace to update: " WORKSPACE_NAME
fi

print_bold_orange_text "Updating workspace: $WORKSPACE_NAME"

if ! "$TF_CMD" workspace select "$WORKSPACE_NAME"; then
    print_bold_red_text "Failed to select workspace '$WORKSPACE_NAME'"
    exit 1
fi

trap "cleanup ${WORKSPACE_NAME}" INT QUIT TERM

"$TF_CMD" apply -auto-approve -var-file terraform.tfvars -var "workspace_name=${WORKSPACE_NAME}"

print_bold_orange_text "Update complete!"
