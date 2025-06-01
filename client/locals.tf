locals {
  ls-client-cloud-init = <<-EOF
#cloud-config
# focal requires `ubuntu_advantage`
ubuntu_advantage:
  token: ${var.pro_token}
# jammy onwards ignores deprecated key `ubuntu_advantage` and uses `ubuntu_pro`
ubuntu_pro:
  token: ${var.pro_token}
runcmd:
  # on Jammy, snap "core22" assumes unsupported features: snapd2.55.5
  - snap refresh snapd
  - pro enable livepatch || ua enable livepatch
  - systemctl stop unattended-upgrades
  - systemctl disable unattended-upgrades
  - echo | openssl s_client -connect "${var.haproxy_ip}:443" | openssl x509 | sudo tee /var/snap/landscape-client/common/etc/server.pem
  - snap install landscape-client --edge
  - |
    landscape-client.config --silent \
      --account-name="${var.landscape_account_name}" \
      --computer-title="$(hostname --long)" \
      --url "https://${var.haproxy_ip}/message-system" \
      --ping-url "http://${var.haproxy_ip}/ping" \
      --script-users="${var.script_users}" \
      --access-group="${var.access_group}" \
      --registration-key="${var.registration_key}" \
      --ssl-public-key="/var/snap/landscape-client/common/etc/server.pem"
EOF
}
