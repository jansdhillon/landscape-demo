#!/bin/bash
set -euo pipefail

source ./utils.sh

check_for_tfvars

PRO_TOKEN=$(get_tfvar 'pro_token')
if [[ -z "$PRO_TOKEN" ]]; then
    print_bold_red_text "'pro_token' is not set! Get your token from https://ubuntu.com/pro/dashboard and set it in terraform.tfvars."
    exit 1
fi

PATH_TO_SSH_KEY=$(get_tfvar 'path_to_ssh_key')
if [[ -z "$PATH_TO_SSH_KEY" ]]; then
    print_bold_red_text "'path_to_ssh_key' not set! Please set it in terraform.tfvars."
    exit 1
fi

"$TF_CMD" init

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

print_bold_orange_text "Workspace name: $WORKSPACE_NAME"

if ! "$TF_CMD" workspace new "$WORKSPACE_NAME" 2>/dev/null; then
    read -r -p "Use existing workspace '$WORKSPACE_NAME'? (y/n) " answer
    [ "${answer:-}" = "y" ] || exit 1
fi

"$TF_CMD" workspace select "$WORKSPACE_NAME"

trap "cleanup ${WORKSPACE_NAME}" INT QUIT TERM

"$TF_CMD" apply -auto-approve -var-file terraform.tfvars -var "workspace_name=${WORKSPACE_NAME}"

ADMIN_EMAIL=$(get_tfvar 'admin_email')
ADMIN_PASSWORD=$(get_tfvar 'admin_password')
DOMAIN=$(get_tfvar 'domain')
HOSTNAME_VAR=$(get_tfvar 'hostname')
LANDSCAPE_ROOT_URL="${HOSTNAME_VAR}.${DOMAIN}"

echo ""
print_bold_orange_text "Setup complete!"
echo -e "Add the HAProxy IP (pre-26.04) or Landscape Server IP (26.04 LTS beta+) to /etc/hosts:"
echo -e "  <IP>  ${LANDSCAPE_ROOT_URL}"
echo ""
echo -e "Then login at: ${BOLD}https://${LANDSCAPE_ROOT_URL}/new_dashboard${RESET_TEXT}"
echo -e "  Email:    ${BOLD}${ADMIN_EMAIL}${RESET_TEXT}"
echo -e "  Password: ${BOLD}${ADMIN_PASSWORD}${RESET_TEXT}"
