#!/bin/bash
set -euo pipefail

source ./utils.sh

check_for_tfvars

PRO_TOKEN=$(get_tfvar 'pro_token')
if [[ -z "$PRO_TOKEN" ]]; then
    print_bold_red_text "'pro_token' is not set! Please get your token from https://ubuntu.com/pro/dashboard and use it as the value for 'pro_token' in terraform.tfvars."
    exit 1
fi

PATH_TO_SSH_KEY=$(get_tfvar 'path_to_ssh_key')
if [[ -z "$PATH_TO_SSH_KEY" ]]; then
    PATH_TO_SSH_KEY=$(ls ~/.ssh/id_*.pub 2>/dev/null | head -1)
    if [[ -z "$PATH_TO_SSH_KEY" ]]; then
        print_bold_red_text "No SSH public key found! Please generate one with 'ssh-keygen' or set 'path_to_ssh_key' in terraform.tfvars"
        exit 1
    fi
fi

PATH_TO_GPG_PRIVATE_KEY=$(get_tfvar 'path_to_gpg_private_key')
if [ ! -f "$PATH_TO_GPG_PRIVATE_KEY" ]; then
    print_bold_red_text "'${PATH_TO_GPG_PRIVATE_KEY}' not found! Please export a non-password protected GPG key and put the path as 'path_to_gpg_private_key' in terraform.tfvars."
    exit 1
fi

GPG_PRIVATE_KEY_CONTENT=$(process_gpg_private_key "$PATH_TO_GPG_PRIVATE_KEY")

PATH_TO_SSL_CERT=$(get_tfvar 'path_to_ssl_cert')
PATH_TO_SSL_KEY=$(get_tfvar 'path_to_ssl_key')
B64_SSL_CERT=$(check_for_and_b64_encode_ssl_item "${PATH_TO_SSL_CERT}")
B64_SSL_KEY=$(check_for_and_b64_encode_ssl_item "${PATH_TO_SSL_KEY}")

tofu init

echo -e "${BOLD}${ORANGE}"
cat <<'EOF'
@@@@@@@@@@@@@@@@@@
@@@@---@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-######-@@@@
@@@@-########-@@@@
@@@@@@@@@@@@@@@@@@

Welcome to Landscape!
EOF
echo -e "${RESET_TEXT}"

WORKSPACE_NAME="${1:-}"
if [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; then
    WORKSPACE_NAME=$(get_tfvar "workspace_name")
    
    while [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; do
        read -r -p "Enter the name of the workspace: " WORKSPACE_NAME
    done
fi

printf "Workspace name: "
print_bold_orange_text "$WORKSPACE_NAME"

if ! tofu workspace new "$WORKSPACE_NAME"; then
    read -r -p "Use existing workspace? (y/n) " answer
    
    if [ "${answer:-}" == "y" ]; then
        tofu workspace select "$WORKSPACE_NAME"
    else
        exit 1
    fi
fi

trap "cleanup ${WORKSPACE_NAME}" INT
trap "cleanup ${WORKSPACE_NAME}" QUIT
trap "cleanup ${WORKSPACE_NAME}" TERM

deploy_landscape_server "$WORKSPACE_NAME" "$B64_SSL_CERT" "$B64_SSL_KEY" "$GPG_PRIVATE_KEY_CONTENT"

HAPROXY_IP=$(server/get_haproxy_ip.sh "$WORKSPACE_NAME" | yq -r ".ip_address")
DOMAIN=$(get_tfvar 'domain')
HOSTNAME=$(get_tfvar 'hostname')
LANDSCAPE_ROOT_URL="${HOSTNAME}.${DOMAIN}"

update_etc_hosts "${HAPROXY_IP}" "${LANDSCAPE_ROOT_URL}"

# Sometimes cloud-init will report an error even if it works
set +e +o pipefail
deploy_landscape_client "$WORKSPACE_NAME" "$B64_SSL_CERT" "$B64_SSL_KEY"

ADMIN_EMAIL=$(get_tfvar 'admin_email')
ADMIN_PASSWORD=$(get_tfvar 'admin_password')

echo -e "${BOLD}${ORANGE}Setup complete 🚀${RESET_TEXT}\nYou can now login at ${BOLD}https://${LANDSCAPE_ROOT_URL}/new_dashboard${RESET_TEXT} using the following credentials:\n${BOLD}Email:${RESET_TEXT} ${ADMIN_EMAIL}\n${BOLD}Password:${RESET_TEXT} ${ADMIN_PASSWORD}\n"
