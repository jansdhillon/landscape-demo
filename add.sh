#!/bin/bash

token="$(grep '^TOKEN=' variables.txt | cut -d'=' -f2)" # FROM ubuntu.com/pro/dashboard
landscape_fqdn="landscape.example.com"
landscape_account_name="standalone"
http_proxy=""
https_proxy=""
script_users="ALL"
tags=""
access_group="global"
registration_key=""

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
  - echo -n | openssl s_client -connect $landscape_fqdn:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /etc/landscape/server.pem
  - landscape-config --silent --account-name="$landscape_account_name" --computer-title="\$(hostname --long)" --url "https://$landscape_fqdn/message-system" --ping-url "http://$landscape_fqdn/ping" --ssl-public-key=/etc/landscape/server.pem --tags="$tags" --script-users="$script_users" --http-proxy="$http_proxy" --https-proxy="$https_proxy" --access-group="$access_group" --registration-key="$registration_key"
  - pro enable livepatch
EOF
)

arch="amd64"
lxd_virtualmachines=("jammy" "noble" "focal")
lxd_containers=("jammy" "noble" "focal" "bionic")
multipass_virtualmachines=("core24")

declare -A lxd_virtualmachine_fingerprints
lxd_virtualmachine_fingerprints=(
  ["focal"]="fb944b6797cf25fd4c7b8035c7e8fa0082d845032336746d94a0fb4db22bd563"
)

declare -A container_fingerprints
container_fingerprints=(
  ["bionic"]="c533845b5db1747674ee915cbb20df6eb47c953bb7caf1fec5b35ae9ccf98c18"
)

today=$(date +%a%H%M | tr '[:upper:]' '[:lower:]')

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