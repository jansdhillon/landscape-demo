#!/bin/bash
set -euo pipefail

source ./utils.sh

PATH_TO_SSL_CERT=$(get_tfvar 'path_to_ssl_cert')
PATH_TO_SSL_KEY=$(get_tfvar 'path_to_ssl_key')
B64_SSL_CERT=$(check_for_and_b64_encode_ssl_item "${PATH_TO_SSL_CERT}")
B64_SSL_KEY=$(check_for_and_b64_encode_ssl_item "${PATH_TO_SSL_KEY}")

WORKSPACE_NAME="${1:-}"
if [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; then
    read -r -p "Enter the name of the workspace to update: " WORKSPACE_NAME
fi

printf "Updating workspace: "
print_bold_orange_text "$WORKSPACE_NAME"

if ! terraform workspace select "$WORKSPACE_NAME"; then
    print_bold_red_text "Failed to select workspace '$WORKSPACE_NAME'"
    exit 1
fi

trap "cleanup ${WORKSPACE_NAME}" INT
trap "cleanup ${WORKSPACE_NAME}" QUIT
trap "cleanup ${WORKSPACE_NAME}" TERM

PATH_TO_GPG_PRIVATE_KEY=$(get_tfvar 'path_to_gpg_private_key')
GPG_PRIVATE_KEY_CONTENT=""
if [ -f "$PATH_TO_GPG_PRIVATE_KEY" ]; then
    GPG_PRIVATE_KEY_CONTENT=$(process_gpg_private_key "$PATH_TO_GPG_PRIVATE_KEY")
fi
print_bold_orange_text "Updating Landscape Server..."
deploy_landscape "$WORKSPACE_NAME" "$B64_SSL_CERT" "$B64_SSL_KEY" "$GPG_PRIVATE_KEY_CONTENT"

HAPROXY_IP=$(./get_haproxy_ip.sh "$WORKSPACE_NAME" | yq -r ".ip_address")
DOMAIN=$(get_tfvar 'domain')
HOSTNAME=$(get_tfvar 'hostname')
LANDSCAPE_ROOT_URL="${HOSTNAME}.${DOMAIN}"

update_etc_hosts "${HAPROXY_IP}" "${LANDSCAPE_ROOT_URL}"

print_bold_orange_text "Updating Landscape Client..."
deploy_landscape_client "$WORKSPACE_NAME" "$B64_SSL_CERT" "$B64_SSL_KEY"

ADMIN_EMAIL=$(get_tfvar 'admin_email')
ADMIN_PASSWORD=$(get_tfvar 'admin_password')

echo -e "${BOLD}${ORANGE}Update complete 🚀${RESET_TEXT}\nYou can now login at ${BOLD}https://${LANDSCAPE_ROOT_URL}/new_dashboard${RESET_TEXT} using the following credentials:\n${BOLD}Email:${RESET_TEXT} ${ADMIN_EMAIL}\n${BOLD}Password:${RESET_TEXT} ${ADMIN_PASSWORD}\n"
