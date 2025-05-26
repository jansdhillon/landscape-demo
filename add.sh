#!/bin/bash



# Deploy Landscape units with Juju

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
INSTANCE_NAME="$TODAY-self-hosted-${LANDSCAPE_FQDN//./-}"
if [ -n "$LANDSCAPE_FQDN" ]; then
  sudo sed -i "/$LANDSCAPE_FQDN/d" /etc/hosts
else
  echo "Error: LANDSCAPE_FQDN is empty. Aborting changes to /etc/hosts."
fi
lxc launch ubuntu:noble "$INSTANCE_NAME" --config=user.user-data="$(cat cloud-init.yaml) --verbose"
lxc exec "$INSTANCE_NAME" --verbose -- cloud-init status --wait
LANDSCAPE_IP=$(lxc info "$INSTANCE_NAME" | grep -E 'inet:.*global' | awk '{print $2}' | cut -d/ -f1)
echo "$LANDSCAPE_IP $LANDSCAPE_FQDN" | sudo tee -a /etc/hosts > /dev/null

for PORT in 6554 443 80; do lxc config device add "$SERVER_INSTANCE_NAME" tcp${PORT}proxyv4 proxy listen=tcp:0.0.0.0:${PORT} connect=tcp:"${LANDSCAPE_IP}":${PORT}; done

echo "Visit https://$LANDSCAPE_FQDN to create the first admin"
read -r -p "then press Enter to continue provisioning Landscape Client instances, or CTRL+C to exit..."



PRO_TOKEN="$(grep '^TOKEN=' variables.txt | cut -d'=' -f2)" # FROM ubuntu.com/pro/dashboard
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
CLIENT_CLOUD_INIT=$(cat <<EOF
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
  - pro attach $PRO_TOKEN
  - landscape-config --silent --account-name="$LANDSCAPE_ACCOUNT_NAME" --computer-title="\$(hostname --long)" --url "https://$LANDSCAPE_FQDN/message-system" --ping-url "http://$LANDSCAPE_FQDN/ping" --tags="$TAGS" --script-users="$SCRIPT_USERS" --http-proxy="$HTTP_PROXY" --https-proxy="$HTTPS_PROXY" --access-group="$ACCESS_GROUP" --registration-key="$REGISTRATION_KEY"
  - pro enable livepatch
EOF
)
else
    # If neither CERTBOT nor both SSL_CERTIFICATE_FILE and SSL_CERTIFICATE_KEY_FILE are set, use a self-signed SSL configuration
CLIENT_CLOUD_INIT=$(cat <<EOF
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
  - pro attach $PRO_TOKEN
  - echo | openssl s_client -connect $LANDSCAPE_FQDN:443 | openssl x509 | tee /etc/landscape/server.pem
  - landscape-config --silent --account-name="$LANDSCAPE_ACCOUNT_NAME" --computer-title="\$(hostname --long)" --url "https://$LANDSCAPE_FQDN/message-system" --ping-url "http://$LANDSCAPE_FQDN/ping" --ssl-public-key=/etc/landscape/server.pem --tags="$TAGS" --script-users="$SCRIPT_USERS" --http-proxy="$HTTP_PROXY" --https-proxy="$HTTPS_PROXY" --access-group="$ACCESS_GROUP" --registration-key="$REGISTRATION_KEY"
  - pro enable livepatch
EOF
)
fi

ARCH="amd64"
LXD_VIRTUALMACHINES=("jammy" "noble")
LXD_CONTAINERS=("jammy" "noble")

declare -A LXD_VIRTUALMACHINE_FINGERPRINTS
LXD_VIRTUALMACHINE_FINGERPRINTS=(
  ["focal"]="fb944b6797cf25fd4c7b8035c7e8fa0082d845032336746d94a0fb4db22bd563"
)

declare -A CONTAINER_FINGERPRINTS
CONTAINER_FINGERPRINTS=(
  ["bionic"]="c533845b5db1747674ee915cbb20df6eb47c953bb7caf1fec5b35ae9ccf98c18"
)

# Launch LXD instances

get_fingerprint() {
  local RELEASE=$1
  local TYPE=$2
  lxc image list ubuntu: arch=$ARCH release="$RELEASE" type="$TYPE" --format yaml | \
    yq e ".[] | .fingerprint" - | tail -1
}

for RELEASE in "${LXD_VIRTUALMACHINES[@]}"; do
  SERVER_INSTANCE_NAME="$TODAY-vm-$RELEASE-$(shuf -i 100-999 -n 1)"
  if [[ -n "${LXD_VIRTUALMACHINE_FINGERPRINTS[$RELEASE]}" ]]; then
    FINGERPRINT=${LXD_VIRTUALMACHINE_FINGERPRINTS[$RELEASE]}
  else
    FINGERPRINT=$(get_fingerprint "$RELEASE" "virtual-machine")
    echo "Retrieved fingerprint for $RELEASE VM: $FINGERPRINT"
  fi
  if [ -n "$FINGERPRINT" ]; then
    echo "$RELEASE VM image fingerprint: $FINGERPRINT"
    lxc launch ubuntu:"$FINGERPRINT" "$SERVER_INSTANCE_NAME" --vm --config=user.user-data="$CLIENT_CLOUD_INIT"
  else
    echo "No fingerprint found for release $RELEASE VM."
  fi
done

for RELEASE in "${LXD_CONTAINERS[@]}"; do
  SERVER_INSTANCE_NAME="$TODAY-c-$RELEASE-$(shuf -i 100-999 -n 1)"
  if [[ -n "${CONTAINER_FINGERPRINTS[$RELEASE]}" ]]; then
    FINGERPRINT=${CONTAINER_FINGERPRINTS[$RELEASE]}
  else
    FINGERPRINT=$(get_fingerprint "$RELEASE" "container")
    echo "Retrieved fingerprint for $RELEASE container: $FINGERPRINT"
  fi
  if [ -n "$FINGERPRINT" ]; then
    echo "$RELEASE container image fingerprint: $FINGERPRINT"
    lxc launch ubuntu:"$FINGERPRINT" "$SERVER_INSTANCE_NAME" --config=user.user-data="$CLIENT_CLOUD_INIT --verbose"
  else
    echo "No fingerprint found for release $RELEASE container."
  fi
done
