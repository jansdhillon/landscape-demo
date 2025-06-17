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
  
  exit
}

trap cleanup SIGINT

printf "Setting up Landscape...\n"

tofu init

tofu apply -auto-approve -var-file terraform.tfvars

HAPROXY_IP=$(tofu output haproxy_ip | tr -d "\"")
LANDSCAPE_ROOT_URL=$(tofu output landscape_root_url | tr -d "\"")
ADMIN_EMAIL=$(tofu output admin_email | tr -d "\"")
ADMIN_PASSWORD=$(tofu output admin_password | tr -d "\"")
printf "Using 'sudo' to modify /etc/hosts...\n"
printf "%s %s\n" "$HAPROXY_IP" "$LANDSCAPE_ROOT_URL" | sudo tee -a /etc/hosts >/dev/null

echo -e "${BOLD}Setup complete 🚀${RESET_TEXT}\nYou can now login at ${BOLD}https://${LANDSCAPE_ROOT_URL}/new_dashboard${RESET_TEXT} using the following credentials:\n${BOLD}Email:${RESET_TEXT} ${ADMIN_EMAIL}\n${BOLD}Password:${RESET_TEXT} ${ADMIN_PASSWORD}\n"
