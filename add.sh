#!/bin/bash

today=$(date +%a%H%M | tr '[:upper:]' '[:lower:]')

# Extract values from variables.txt
HOSTNAME=$(grep '^HOSTNAME=' variables.txt | cut -d'=' -f2 | tr -d '[:space:]')
DOMAIN=$(grep '^DOMAIN=' variables.txt | cut -d'=' -f2 | tr -d '[:space:]')
CERTBOT=$(grep '^CERTBOT=' variables.txt | cut -d'=' -f2)
SSL_CERTIFICATE_PATH=$(grep '^SSL_CERTIFICATE_PATH=' variables.txt | cut -d'=' -f2)
SSL_CERTIFICATE_KEY_PATH=$(grep '^SSL_CERTIFICATE_KEY_PATH=' variables.txt | cut -d'=' -f2)

# Construct Landscape FQDN based on available values
if [ -n "$HOSTNAME" ] && [ -n "$DOMAIN" ]; then
  landscape_fqdn="${HOSTNAME}.${DOMAIN}"
elif [ -n "$HOSTNAME" ]; then
  landscape_fqdn="${HOSTNAME}"
elif [ -n "$DOMAIN" ]; then
  landscape_fqdn="${DOMAIN}"
else
  landscape_fqdn="landscape.example.com"
fi

# Provision Landscape Server into LXD Container

# get Landscape Server cloud-init.yaml template
curl -o cloud-init.yaml https://raw.githubusercontent.com/canonical/landscape-scripts/main/provisioning/cloud-init-quickstart.yaml
# populate the template with information from variables.txt
while IFS='=' read -r key value; do sed -i "s|{% set $key = '.*' %}|{% set $key = '$value' %}|" cloud-init.yaml; done < variables.txt
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
## launch Noble instance with the Landscape Server cloud-init.yaml
instance_name="$today-${landscape_fqdn//./-}"
sudo sed -i "/$landscape_fqdn/d" /etc/hosts
lxc launch ubuntu:24.04 "$instance_name" --config=user.user-data="$(cat cloud-init.yaml)"
lxc exec "$instance_name" -- cloud-init status --wait
# while [ -z "$LANDSCAPE_IP" ]; do LANDSCAPE_IP=$(lxc info "$instance_name" | grep -E 'inet:.*global' | awk '{print $2}' | cut -d/ -f1); [ -z "$LANDSCAPE_IP" ] && sleep 1; done
LANDSCAPE_IP=$(lxc info "$instance_name" | grep -E 'inet:.*global' | awk '{print $2}' | cut -d/ -f1)
echo "$LANDSCAPE_IP $landscape_fqdn" | sudo tee -a /etc/hosts > /dev/null
for PORT in 6554 443 80; do lxc config device add "$instance_name" tcp${PORT}proxyv4 proxy listen=tcp:0.0.0.0:${PORT} connect=tcp:${LANDSCAPE_IP}:${PORT}; done

echo "Visit https://$landscape_fqdn to finalize Landscape Server configuration,"
read -p "then press Enter to continue provisioning Ubuntu instances..."

token="$(grep '^TOKEN=' variables.txt | cut -d'=' -f2)" # FROM ubuntu.com/pro/dashboard
landscape_account_name="standalone"
http_proxy=""
https_proxy=""
script_users="ALL"
tags=""
access_group="global"
registration_key=""

# Determine if CERTBOT is set or both SSL_CERTIFICATE_FILE and SSL_CERTIFICATE_KEY_FILE are set
if [[ -n "$CERTBOT" || (-n "$SSL_CERTIFICATE_FILE" && -n "$SSL_CERTIFICATE_KEY_FILE") ]]; then
    # If CERTBOT is set, or both SSL_CERTIFICATE_FILE and SSL_CERTIFICATE_KEY_FILE are set, use the valid SSL configuration
cloud_init=$(cat <<EOF
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
  - pro attach $token
  - landscape-config --silent --account-name="$landscape_account_name" --computer-title="\$(hostname --long)" --url "https://$landscape_fqdn/message-system" --ping-url "http://$landscape_fqdn/ping" --tags="$tags" --script-users="$script_users" --http-proxy="$http_proxy" --https-proxy="$https_proxy" --access-group="$access_group" --registration-key="$registration_key"
  - pro enable livepatch
EOF
)
else
    # If neither CERTBOT nor both SSL_CERTIFICATE_FILE and SSL_CERTIFICATE_KEY_FILE are set, use a self-signed SSL configuration
cloud_init=$(cat <<EOF
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
  - pro attach $token
  - echo | openssl s_client -connect $landscape_fqdn:443 | openssl x509 | tee /etc/landscape/server.pem
  - landscape-config --silent --account-name="$landscape_account_name" --computer-title="\$(hostname --long)" --url "https://$landscape_fqdn/message-system" --ping-url "http://$landscape_fqdn/ping" --ssl-public-key=/etc/landscape/server.pem --tags="$tags" --script-users="$script_users" --http-proxy="$http_proxy" --https-proxy="$https_proxy" --access-group="$access_group" --registration-key="$registration_key"
  - pro enable livepatch
EOF
)
fi

arch="amd64"
lxd_virtualmachines=("jammy" "noble" "focal")
lxd_containers=("jammy" "noble" "bionic")
multipass_virtualmachines=("core24")

declare -A lxd_virtualmachine_fingerprints
lxd_virtualmachine_fingerprints=(
  ["focal"]="fb944b6797cf25fd4c7b8035c7e8fa0082d845032336746d94a0fb4db22bd563"
)

declare -A container_fingerprints
container_fingerprints=(
  ["bionic"]="c533845b5db1747674ee915cbb20df6eb47c953bb7caf1fec5b35ae9ccf98c18"
)

# Launch Multipass instances

for release in "${multipass_virtualmachines[@]}"; do
  echo "$release virtual machine: latest"
  multipass launch "$release" -n "$today"-"$release"
  multipass exec "$today"-"$release" -- sudo snap install landscape-client
  echo | openssl s_client -connect $landscape_fqdn:443 | openssl x509 | multipass transfer --parents - "$today"-"$release":/home/ubuntu/certs/landscape.pem
  multipass exec "$today"-"$release" -- sudo cp /home/ubuntu/certs/landscape.pem /var/snap/landscape-client/common/etc/landscape.pem
  multipass exec "$today"-"$release" -- sudo landscape-client.config --silent --account-name="$landscape_account_name" --computer-title="$today-$release" --url "https://$landscape_fqdn/message-system" --ping-url "http://$landscape_fqdn/ping" --ssl-public-key=/var/snap/landscape-client/common/etc/landscape.pem --tags="$tags" --script-users="$script_users" --http-proxy="$http_proxy" --https-proxy="$https_proxy" --access-group="$access_group" --registration-key="$registration_key"
done

# Launch LXD instances

get_fingerprint() {
  local release=$1
  local type=$2
  lxc image list ubuntu: arch=$arch release="$release" type="$type" --format yaml | \
    yq e ".[] | .fingerprint" - | tail -1
}

for release in "${lxd_virtualmachines[@]}"; do
  if [[ -n "${lxd_virtualmachine_fingerprints[$release]}" ]]; then
    fingerprint=${lxd_virtualmachine_fingerprints[$release]}
  else
    fingerprint=$(get_fingerprint "$release" "virtual-machine")
    echo "Retrieved fingerprint for $release VM: $fingerprint"
  fi
  if [ -n "$fingerprint" ]; then
    echo "$release VM image fingerprint: $fingerprint"
    lxc launch ubuntu:"$fingerprint" "$today-$release-vm" --vm --config=user.user-data="$cloud_init"
  else
    echo "No fingerprint found for release $release VM."
  fi
done

for release in "${lxd_containers[@]}"; do
  if [[ -n "${container_fingerprints[$release]}" ]]; then
    fingerprint=${container_fingerprints[$release]}
  else
    fingerprint=$(get_fingerprint "$release" "container")
    echo "Retrieved fingerprint for $release container: $fingerprint"
  fi
  if [ -n "$fingerprint" ]; then
    echo "$release container image fingerprint: $fingerprint"
    lxc launch ubuntu:"$fingerprint" "$today-$release-c" --config=user.user-data="$cloud_init"
  else
    echo "No fingerprint found for release $release container."
  fi
done