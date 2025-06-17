#!/bin/bash

set -x

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

  exit
}

trap cleanup SIGINT

printf "Setting up Landscape...\n"

tofu init

PATH_TO_SSL_CERT=$(cat terraform.tfvars.json | yq '.path_to_ssl_cert')
PATH_TO_SSL_KEY=$(cat terraform.tfvars.json | yq '.path_to_ssl_key')

if [ -n "$PATH_TO_SSL_CERT" ] && [ "$PATH_TO_SSL_CERT" != "null" ] &&
  [ -n "$PATH_TO_SSL_KEY" ] && [ "$PATH_TO_SSL_KEY" != "null" ]; then
  printf "Using 'sudo' to read SSL cert/key...\n"
  B64_SSL_CERT=$(sudo base64 "$PATH_TO_SSL_CERT" 2>/dev/null)
  B64_SSL_KEY=$(sudo base64 "$PATH_TO_SSL_KEY" 2>/dev/null)

  if [ -z "$B64_SSL_CERT" ] || [ -z "$B64_SSL_KEY" ]; then
    printf "Failed to encode SSL cert/key\n"
    exit 1
  fi
fi

if [ -n "$B64_SSL_CERT" ] && [ -n "$B64_SSL_KEY" ]; then
  tofu apply -auto-approve -var-file terraform.tfvars.json \
    -var "b64_ssl_cert=${B64_SSL_CERT}" \
    -var "b64_ssl_key=${B64_SSL_KEY}"
else
  tofu apply -auto-approve -var-file terraform.tfvars.json
fi

HAPROXY_IP=$(tofu output haproxy_ip | tr -d "\"")
LANDSCAPE_ROOT_URL=$(tofu output landscape_root_url | tr -d "\"")
ADMIN_EMAIL=$(tofu output admin_email | tr -d "\"")
ADMIN_PASSWORD=$(tofu output admin_password | tr -d "\"")
printf "Using 'sudo' to modify /etc/hosts...\n"
printf "%s %s\n" "$HAPROXY_IP" "$LANDSCAPE_ROOT_URL" | sudo tee -a /etc/hosts >/dev/null

echo -e "${BOLD}Setup complete 🚀${RESET_TEXT}\nYou can now login at ${BOLD}https://${LANDSCAPE_ROOT_URL}/new_dashboard${RESET_TEXT} using the following credentials:\n${BOLD}Email:${RESET_TEXT} ${ADMIN_EMAIL}\n${BOLD}Password:${RESET_TEXT} ${ADMIN_PASSWORD}\n"
