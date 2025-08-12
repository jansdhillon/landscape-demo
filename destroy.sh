#!/bin/bash
source ./utils.sh

check_for_tfvars

WORKSPACE_NAME="${1:-}"

if [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; then
    read -r -p "Enter the name of the workspace to destroy: " WORKSPACE_NAME
fi

if ! tofu workspace select "$WORKSPACE_NAME"; then
    exit
fi

printf "Cleaning up workspace: "
print_bold_orange_text "$WORKSPACE_NAME"

HAPROXY_JSON=$(./get_haproxy_ip.sh "$WORKSPACE_NAME" 0 2>/dev/null || true)

if echo "$HAPROXY_JSON" | yq -e -r '.ip_address' &>/dev/null; then
    HAPROXY_IP=$(echo "$HAPROXY_JSON" | yq -r '.ip_address')
else
    print_bold_red_text "Failed to get HAProxy IP address."
    HAPROXY_IP=""
fi

tofu destroy -auto-approve -var-file terraform.tfvars -var "workspace_name=${WORKSPACE_NAME}"
tofu workspace select default
tofu workspace delete "$WORKSPACE_NAME"

juju switch controller

# Ideally we wouldn't have to do this but often it will get stuck 'destroying'...
if ! juju destroy-model --no-prompt "$WORKSPACE_NAME" --no-wait --force --destroy-storage; then
    exit
fi

if [[ -n "${HAPROXY_IP:-}" && "${HAPROXY_IP:-}" != "null" ]]; then
    print_bold_orange_text "Using 'sudo' to remove all entries for IP ${HAPROXY_IP} from /etc/hosts..."
    sudo sed -i "/${HAPROXY_IP}/d" /etc/hosts
fi

# Unfortunately, the Multipass provider for Terraform does not allow us to configure the timeout
# and it's common for it to timeout while provisioning, so it won't be destroyed with the rest.
# To remedy this, we manually find and delete any core devices that were created.

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

exit
