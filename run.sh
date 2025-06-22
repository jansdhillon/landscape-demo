#!/bin/bash
set -euxo pipefail

BOLD="\e[1m"
ORANGE="\e[33m"
RESET_TEXT="\e[0m"

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
    WORKSPACE_NAME=$(cat terraform.tfvars.json | yq '.workspace_name')

    while [ -z "${WORKSPACE_NAME:-}" ] || [ "${WORKSPACE_NAME:-}" == "null" ]; do
        read -r -p "Enter the name of the workspace: " WORKSPACE_NAME
    done

fi

if ! tofu workspace new "$WORKSPACE_NAME"; then
    read -r -p "Use existing workspace? (y/n) " answer

    if [ "${answer:-}" == "y" ]; then
        tofu workspace select "$WORKSPACE_NAME"
    else
        exit
    fi
fi

printf "Workspace name: $WORKSPACE_NAME\n"

cleanup() {
    printf "Cleaning up workspace: $WORKSPACE_NAME\n"
    ./destroy.sh "$WORKSPACE_NAME"
}

trap cleanup SIGINT

tofu init

PATH_TO_SSL_CERT=$(cat terraform.tfvars.json | yq '.path_to_ssl_cert')
PATH_TO_SSL_KEY=$(cat terraform.tfvars.json | yq '.path_to_ssl_key')
PATH_TO_GPG_PRIVATE_KEY=$(cat terraform.tfvars.json | yq '.path_to_gpg_private_key')

printf "Using 'sudo' to read GPG private key...\n"
sudo cp "$PATH_TO_GPG_PRIVATE_KEY" gpg_private_key
sudo chown "$(whoami)" "gpg_private_key"
# URL-encode it
GPG_PRIVATE_KEY_CONTENT=$(yq -r 'load_str("gpg_private_key") | @uri' /dev/null)
sudo rm gpg_private_key

if [ -n "${PATH_TO_SSL_CERT:-}" ] && [ "${PATH_TO_SSL_CERT:-}" != "null" ] &&
    [ -n "${PATH_TO_SSL_KEY:-}" ] && [ "${PATH_TO_SSL_KEY:-}" != "null" ]; then
    printf "Using 'sudo' to read SSL cert/key...\n"
    B64_SSL_CERT=$(sudo base64 "$PATH_TO_SSL_CERT" 2>/dev/null)
    B64_SSL_KEY=$(sudo base64 "$PATH_TO_SSL_KEY" 2>/dev/null)
    if [ -z "$B64_SSL_CERT" ] || [ -z "$B64_SSL_KEY" ]; then
        printf "Failed to encode SSL cert/key\n"
        cleanup
    fi
fi

# Deploy Landscape Server module (by excluding the Client module)
if [ -n "${B64_SSL_CERT:-}" ] && [ -n "${B64_SSL_KEY:-}" ]; then
    if ! tofu plan -var-file terraform.tfvars.json \
        -var "b64_ssl_cert=${B64_SSL_CERT}" \
        -var "b64_ssl_key=${B64_SSL_KEY}"; then
        printf 'Error running plan!\n'
        cleanup
    fi
    tofu apply -auto-approve -var-file terraform.tfvars.json \
        -exclude module.landscape_client \
        -var "workspace_name=${WORKSPACE_NAME}" \
        -var "b64_ssl_cert=${B64_SSL_CERT}" \
        -var "b64_ssl_key=${B64_SSL_KEY}" \
        -var "gpg_private_key_content=${GPG_PRIVATE_KEY_CONTENT}"
else
    if ! tofu plan -var-file terraform.tfvars.json; then
        printf 'Error running plan!\n'
        cleanup
    fi

    tofu apply -auto-approve \
        -exclude module.landscape_client \
        -var-file terraform.tfvars.json \
        -var "workspace_name=${WORKSPACE_NAME}" \
        -var "gpg_private_key_content=${GPG_PRIVATE_KEY_CONTENT}"
fi

# Could also get from output
HAPROXY_IP=$(server/get_haproxy_ip.sh "$WORKSPACE_NAME" | yq -r ".ip_address")
DOMAIN=$(cat terraform.tfvars.json | yq '.domain')
HOSTNAME=$(cat terraform.tfvars.json | yq '.hostname')
LANDSCAPE_ROOT_URL="${HOSTNAME}.${DOMAIN}"
ADMIN_EMAIL=$(cat terraform.tfvars.json | yq '.admin_email')
ADMIN_PASSWORD=$(cat terraform.tfvars.json | yq '.admin_password')

if [ -n "${HAPROXY_IP}" ] && [ -n "${LANDSCAPE_ROOT_URL}" ]; then
    printf "Using 'sudo' to modify /etc/hosts...\n"
    printf "%s %s\n" "$HAPROXY_IP" "$LANDSCAPE_ROOT_URL" | sudo tee -a /etc/hosts >/dev/null
else
    printf "Failed to retrieve HAProxy IP or Landscape root URL, aborting changes to /etc/hosts...\n"
fi

# Deploy Landscape Client module

# Sometimes cloud-init will report an error even if it works
set +e +o pipefail
# Don't overwrite vars
if [ -n "${B64_SSL_CERT:-}" ] && [ -n "${B64_SSL_KEY:-}" ]; then
    tofu apply -auto-approve \
        -var-file terraform.tfvars.json \
        -var "workspace_name=${WORKSPACE_NAME}" \
        -var "b64_ssl_cert=${B64_SSL_CERT}" \
        -var "b64_ssl_key=${B64_SSL_KEY}"
else
    tofu apply -auto-approve \
        -var-file terraform.tfvars.json \
        -var "workspace_name=${WORKSPACE_NAME}"
        
fi

echo -e "${BOLD}Setup complete 🚀${RESET_TEXT}\nYou can now login at ${BOLD}https://${LANDSCAPE_ROOT_URL}/new_dashboard${RESET_TEXT} using the following credentials:\n${BOLD}Email:${RESET_TEXT} ${ADMIN_EMAIL}\n${BOLD}Password:${RESET_TEXT} ${ADMIN_PASSWORD}\n"
