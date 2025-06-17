#!/bin/bash
set -euxo pipefail

BOLD="\e[1m"
ORANGE="\e[33m"
RESET_TEXT="\e[0m"

bold_orange_text() {
    local text=$1
    echo -e "${BOLD}${ORANGE}${text}${RESET_TEXT}"
}

cat <<EOF
@@@@@@@@@@@@@@@@@@
@@@@---@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-@@@@@@@@@@@
@@@@-#-######-@@@@
@@@@-########-@@@@
@@@@@@@@@@@@@@@@@@
EOF

bold_orange_text 'Welcome to Landscape!'

cleanup() {
    printf "Cleaning up and exiting...\n"
    if [ -n "${HAPROXY_IP:-}" ]; then
        printf "Using 'sudo' to remove all entries for IP ${HAPROXY_IP} from /etc/hosts...\n"
        sudo sed -i "/${HAPROXY_IP}/d" /etc/hosts
    fi
    tofu destroy -auto-approve
    if [ -n "${WORKSPACE_NAME:-}" ]; then
        tofu workspace select default
        tofu workspace delete "$WORKSPACE_NAME"

        # Ideally we wouldn't have to do this manually
        # but often it will get stuck 'destroying'
        juju destroy-model --no-prompt "$WORKSPACE_NAME" --no-wait --force
    fi
    exit
}

trap cleanup SIGINT
trap cleanup ERR

printf "Setting up Landscape...\n"
PATH_TO_SSL_CERT=$(cat terraform.tfvars.json | yq '.path_to_ssl_cert')
PATH_TO_SSL_KEY=$(cat terraform.tfvars.json | yq '.path_to_ssl_key')
WORKSPACE_NAME=$(cat terraform.tfvars.json | yq '.workspace_name')
tofu init

printf "Workspace name: $WORKSPACE_NAME\n"
if ! tofu workspace new "$WORKSPACE_NAME"; then
    tofu workspace select "$WORKSPACE_NAME"
fi

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

# Deploy Landscape Server module
if [ -n "${B64_SSL_CERT:-}" ] && [ -n "${B64_SSL_KEY:-}" ]; then
    if ! tofu plan -var-file terraform.tfvars.json \
        -var "b64_ssl_cert=${B64_SSL_CERT}" \
        -var "b64_ssl_key=${B64_SSL_KEY}"; then
        printf "Error running plan!\n"
        cleanup
    fi
    tofu apply -auto-approve -var-file terraform.tfvars.json \
        -var "b64_ssl_cert=${B64_SSL_CERT}" \
        -var "b64_ssl_key=${B64_SSL_KEY}" \
        -target module.landscape_server
else
    if ! tofu plan -var-file terraform.tfvars.json; then
        printf "Error running plan!\n"
        cleanup
    fi
    tofu apply -auto-approve -var-file terraform.tfvars.json -target module.landscape_server
fi

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
# so this is to avoid triggering cleanup in that case
set +e
tofu apply -auto-approve -var-file terraform.tfvars.json

echo -e "${BOLD}Setup complete 🚀${RESET_TEXT}\nYou can now login at ${BOLD}https://${LANDSCAPE_ROOT_URL}/new_dashboard${RESET_TEXT} using the following credentials:\n${BOLD}Email:${RESET_TEXT} ${ADMIN_EMAIL}\n${BOLD}Password:${RESET_TEXT} ${ADMIN_PASSWORD}\n"
