#!/bin/bash

TODAY=$(date +%a%H%M | tr '[:upper:]' '[:lower:]')

# Extract values from variables.txt
HOSTNAME=$(grep '^HOSTNAME=' variables.txt | cut -d'=' -f2 | tr -d '[:space:]')
DOMAIN=$(grep '^DOMAIN=' variables.txt | cut -d'=' -f2 | tr -d '[:space:]')
CERTBOT=$(grep '^CERTBOT=' variables.txt | cut -d'=' -f2)
SSL_CERTIFICATE_PATH=$(grep '^SSL_CERTIFICATE_PATH=' variables.txt | cut -d'=' -f2)
SSL_CERTIFICATE_KEY_PATH=$(grep '^SSL_CERTIFICATE_KEY_PATH=' variables.txt | cut -d'=' -f2)

# Construct Landscape FQDN based on available values
if [ -n "$HOSTNAME" ] && [ -n "$DOMAIN" ]; then
  LANDSCAPE_FQDN="${HOSTNAME}.${DOMAIN}"
elif [ -n "$HOSTNAME" ]; then
  LANDSCAPE_FQDN="${HOSTNAME}"
elif [ -n "$DOMAIN" ]; then
  LANDSCAPE_FQDN="${DOMAIN}"
else
  LANDSCAPE_FQDN="landscape.example.com"
fi

# Provision Landscape Server into LXD Container

# get Landscape Server cloud-init.yaml template
curl -o cloud-init.yaml https://raw.githubusercontent.com/canonical/landscape-scripts/main/provisioning/cloud-init-quickstart.yaml
# populate the template with information from variables.txt
while IFS='=' read -r KEY VALUE; do sed -i "s|{% set $KEY = '.*' %}|{% set $KEY = '$VALUE' %}|" cloud-init.yaml; done < variables.txt

# check for optional SSL configurations
if [[ -n "$SSL_CERTIFICATE_PATH" ]]; then
  SSL_CERTIFICATE=$(sudo awk '{print "    " $0}' "$SSL_CERTIFICATE_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')
  sed -i "/# - SSL_CERTIFICATE_FILE/a \\  - | \\n    cat <<EOF > /etc/ssl/certs/landscape_server.pem\\n${SSL_CERTIFICATE}\\n    EOF" cloud-init.yaml
fi
if [[ -n "$SSL_CERTIFICATE_KEY_PATH" ]]; then
  SSL_CERTIFICATE_KEY=$(sudo awk '{print "    " $0}' "$SSL_CERTIFICATE_KEY_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')
  sed -i "/# - SSL_CERTIFICATE_KEY_FILE/a \\  - | \\n    cat <<EOF > /etc/ssl/private/landscape_server.key\\n${SSL_CERTIFICATE_KEY}\\n    EOF" cloud-init.yaml
fi

SSL_CERTIFICATE_CHAIN_PATH=$(grep '^SSL_CERTIFICATE_CHAIN_PATH=' variables.txt | cut -d'=' -f2)
if [[ -n "$SSL_CERTIFICATE_CHAIN_PATH" ]]; then
  SSL_CERTIFICATE_CHAIN=$(sudo awk '{print "    " $0}' "$SSL_CERTIFICATE_CHAIN_PATH" | sed ':a;N;$!ba;s/\n/\\n/g')
  sed -i "/# - SSL_CERTIFICATE_CHAIN_FILE/a \\  - | \\n    cat <<EOF > /etc/ssl/certs/landscape_server_ca.crt\\n${SSL_CERTIFICATE_CHAIN}\\n    EOF" cloud-init.yaml
fi

# Launch Noble instance with the Landscape Server cloud-init.yaml
INSTANCE_NAME="$TODAY-lds-${LANDSCAPE_FQDN//./-}"
sudo sed -i "/$LANDSCAPE_FQDN/d" /etc/hosts
lxc launch ubuntu:24.04 "$INSTANCE_NAME" --config=user.user-data="$(cat cloud-init.yaml)"
lxc exec "$INSTANCE_NAME" -- cloud-init status --wait
LANDSCAPE_IP=$(lxc info "$INSTANCE_NAME" | grep -E 'inet:.*global' | awk '{print $2}' | cut -d/ -f1)
echo "$LANDSCAPE_IP $LANDSCAPE_FQDN" | sudo tee -a /etc/hosts > /dev/null

for PORT in 6554 443 80; do lxc config device add "$INSTANCE_NAME" tcp${PORT}proxyv4 proxy listen=tcp:0.0.0.0:${PORT} connect=tcp:"${LANDSCAPE_IP}":${PORT}; done

echo "Visit https://$LANDSCAPE_FQDN to finalize Landscape Server configuration,"
read -r -p "then press Enter to continue provisioning Ubuntu instances..."

TOKEN="$(grep '^TOKEN=' variables.txt | cut -d'=' -f2)" # FROM ubuntu.com/pro/dashboard
LANDSCAPE_ACCOUNT_NAME="standalone"
HTTP_PROXY=""
HTTPS_PROXY=""
SCRIPT_USERS="ALL"
TAGS=""
ACCESS_GROUP="global"
REGISTRATION_KEY=""

# Determine if CERTBOT is set or both SSL_CERTIFICATE_FILE and SSL_CERTIFICATE_KEY_FILE are set
if [[ -n "$CERTBOT" || (-n "$SSL_CERTIFICATE_FILE" && -n "$SSL_CERTIFICATE_KEY_FILE") ]]; then
    # If CERTBOT is set, or both SSL_CERTIFICATE_FILE and SSL_CERTIFICATE_KEY_FILE are set, use the valid SSL configuration
CLOUD_INIT=$(cat <<EOF
#cloud-config
packages:
  - ansible
  - redis
  - phpmyadmin
  - npm
  - ubuntu-pro-client
  - landscape-client
runcmd:
  - systemctl stop unattended-upgrades
  - systemctl disable unattended-upgrades
  - apt-get remove -y unattended-upgrades
  - pro attach $TOKEN
  - landscape-config --silent --account-name="$LANDSCAPE_ACCOUNT_NAME" --computer-title="\$(hostname --long)" --url "https://$LANDSCAPE_FQDN/message-system" --ping-url "http://$LANDSCAPE_FQDN/ping" --tags="$TAGS" --script-users="$SCRIPT_USERS" --http-proxy="$HTTP_PROXY" --https-proxy="$HTTPS_PROXY" --access-group="$ACCESS_GROUP" --registration-key="$REGISTRATION_KEY"
  - pro enable livepatch
EOF
)
else
    # If neither CERTBOT nor both SSL_CERTIFICATE_FILE and SSL_CERTIFICATE_KEY_FILE are set, use a self-signed SSL configuration
CLOUD_INIT=$(cat <<EOF
#cloud-config
packages:
  - ansible
  - redis
  - phpmyadmin
  - npm
  - ubuntu-pro-client
  - landscape-client
runcmd:
  - systemctl stop unattended-upgrades
  - systemctl disable unattended-upgrades
  - apt-get remove -y unattended-upgrades
  - pro attach $TOKEN
  - echo | openssl s_client -connect $LANDSCAPE_FQDN:443 | openssl x509 | tee /etc/landscape/server.pem
  - landscape-config --silent --account-name="$LANDSCAPE_ACCOUNT_NAME" --computer-title="\$(hostname --long)" --url "https://$LANDSCAPE_FQDN/message-system" --ping-url "http://$LANDSCAPE_FQDN/ping" --ssl-public-key=/etc/landscape/server.pem --tags="$TAGS" --script-users="$SCRIPT_USERS" --http-proxy="$HTTP_PROXY" --https-proxy="$HTTPS_PROXY" --access-group="$ACCESS_GROUP" --registration-key="$REGISTRATION_KEY"
  - pro enable livepatch
EOF
)
fi

ARCH="amd64"
LXD_VIRTUALMACHINES=("jammy" "noble" "focal")
LXD_CONTAINERS=("jammy" "noble" "bionic")
MULTIPASS_VIRTUALMACHINES=("core24")

declare -A LXD_VIRTUALMACHINE_FINGERPRINTS
LXD_VIRTUALMACHINE_FINGERPRINTS=(
  ["focal"]="fb944b6797cf25fd4c7b8035c7e8fa0082d845032336746d94a0fb4db22bd563"
)

declare -A CONTAINER_FINGERPRINTS
CONTAINER_FINGERPRINTS=(
  ["bionic"]="c533845b5db1747674ee915cbb20df6eb47c953bb7caf1fec5b35ae9ccf98c18"
)

# Launch Multipass instances

for RELEASE in "${MULTIPASS_VIRTUALMACHINES[@]}"; do
  INSTANCE_NAME="$TODAY-vm-$RELEASE-$(shuf -i 100-999 -n 1)"
  echo "$RELEASE virtual machine: latest"
  multipass launch "$RELEASE" -n "$INSTANCE_NAME"
  multipass exec "$INSTANCE_NAME" -- sudo snap install landscape-client
  echo | openssl s_client -connect "$LANDSCAPE_FQDN":443 | openssl x509 | multipass transfer --parents - "$INSTANCE_NAME":/home/ubuntu/certs/landscape.pem
  multipass exec "$INSTANCE_NAME" -- sudo cp /home/ubuntu/certs/landscape.pem /var/snap/landscape-client/common/etc/landscape.pem
  multipass exec "$INSTANCE_NAME" -- sudo landscape-client.config --silent --account-name="$LANDSCAPE_ACCOUNT_NAME" --computer-title="$INSTANCE_NAME" --url "https://$LANDSCAPE_FQDN/message-system" --ping-url "http://$LANDSCAPE_FQDN/ping" --ssl-public-key=/var/snap/landscape-client/common/etc/landscape.pem --tags="$TAGS" --script-users="$SCRIPT_USERS" --http-proxy="$HTTP_PROXY" --https-proxy="$HTTPS_PROXY" --access-group="$ACCESS_GROUP" --registration-key="$REGISTRATION_KEY"
done

# Launch LXD instances

get_fingerprint() {
  local RELEASE=$1
  local TYPE=$2
  lxc image list ubuntu: arch=$ARCH release="$RELEASE" type="$TYPE" --format yaml | \
    yq e ".[] | .fingerprint" - | tail -1
}

for RELEASE in "${LXD_VIRTUALMACHINES[@]}"; do
  INSTANCE_NAME="$TODAY-vm-$RELEASE-$(shuf -i 100-999 -n 1)"
  if [[ -n "${LXD_VIRTUALMACHINE_FINGERPRINTS[$RELEASE]}" ]]; then
    FINGERPRINT=${LXD_VIRTUALMACHINE_FINGERPRINTS[$RELEASE]}
  else
    FINGERPRINT=$(get_fingerprint "$RELEASE" "virtual-machine")
    echo "Retrieved fingerprint for $RELEASE VM: $FINGERPRINT"
  fi
  if [ -n "$FINGERPRINT" ]; then
    echo "$RELEASE VM image fingerprint: $FINGERPRINT"
    lxc launch ubuntu:"$FINGERPRINT" "$INSTANCE_NAME" --vm --config=user.user-data="$CLOUD_INIT"
  else
    echo "No fingerprint found for release $RELEASE VM."
  fi
done

for RELEASE in "${LXD_CONTAINERS[@]}"; do
  INSTANCE_NAME="$TODAY-c-$RELEASE-$(shuf -i 100-999 -n 1)"
  if [[ -n "${CONTAINER_FINGERPRINTS[$RELEASE]}" ]]; then
    FINGERPRINT=${CONTAINER_FINGERPRINTS[$RELEASE]}
  else
    FINGERPRINT=$(get_fingerprint "$RELEASE" "container")
    echo "Retrieved fingerprint for $RELEASE container: $FINGERPRINT"
  fi
  if [ -n "$FINGERPRINT" ]; then
    echo "$RELEASE container image fingerprint: $FINGERPRINT"
    lxc launch ubuntu:"$FINGERPRINT" "$INSTANCE_NAME" --config=user.user-data="$CLOUD_INIT"
  else
    echo "No fingerprint found for release $RELEASE container."
  fi
done
