#!/bin/bash
source ./utils.sh

check_for_tfvars

WORKSPACE_NAME="${1:-}"

if [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; then
    read -r -p "Enter the name of the workspace to destroy: " WORKSPACE_NAME
fi

if ! "$TF_CMD" workspace select "$WORKSPACE_NAME"; then
    exit 1
fi

print_bold_orange_text "Destroying workspace: $WORKSPACE_NAME"

"$TF_CMD" destroy -auto-approve -var-file terraform.tfvars -var "workspace_name=${WORKSPACE_NAME}"
"$TF_CMD" workspace select default
"$TF_CMD" workspace delete -force "$WORKSPACE_NAME"

juju switch controller
juju destroy-model --no-prompt "$WORKSPACE_NAME" --no-wait --force --destroy-storage || true

# Multipass provider does not support configurable timeouts; manually clean up Ubuntu Core devices.
CORE_COUNT=$(get_tfvar 'ubuntu_core_count')

if [ -n "${CORE_COUNT:-}" ] && [ "$CORE_COUNT" -gt 0 ]; then
    core_name=$(get_tfvar 'ubuntu_core_device_name')
    core_devices=$(multipass list --format=json | yq -r '.list[].name')

    for i in $(seq 0 $((CORE_COUNT - 1))); do
        name="$WORKSPACE_NAME-$core_name-$i"
        if echo "$core_devices" | grep -qx "$name"; then
            echo "Deleting $name..."
            multipass delete "$name" --purge
        fi
    done
fi

print_bold_red_text "Workspace '${WORKSPACE_NAME}' destroyed!"
print_bold_orange_text "Remember to remove the /etc/hosts entry you added for this workspace."
