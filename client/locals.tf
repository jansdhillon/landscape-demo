locals {
  ls-client-cloud-init = <<-EOF
#cloud-config
runcmd:
  - snap refresh snapd
  - systemctl stop unattended-upgrades
  - systemctl disable unattended-upgrades
  - mkdir -p /var/snap/landscape-client/common/etc/
  - pro attach ${var.pro_token}
  - |
    while true; do
      echo | openssl s_client -connect "${var.landscape_fqdn}:443" | openssl x509 | sudo tee /tmp/server.pem
      if [ -s /tmp/server.pem ]; then
        sudo cp /tmp/server.pem /var/snap/landscape-client/common/etc/server.pem
        break
      else
        sleep 5
      fi
    done
  - snap install landscape-client --edge
  - landscape-client.config --silent --account-name="${var.landscape_account_name}" --computer-title="$(hostname --long)" --url "https://${var.landscape_fqdn}/message-system" --ping-url "http://${var.landscape_fqdn}/ping" --script-users="${var.script_users}" --registration-key="${var.registration_key}" --ssl-public-key="/var/snap/landscape-client/common/etc/server.pem"
EOF

  series_to_fingerprint = { "jammy" : "d4104f351699896891aa4c41fb521a15a96cb9c70de0b5e83cb9067faf03833a", "focal" : "fb944b6797cf25fd4c7b8035c7e8fa0082d845032336746d94a0fb4db22bd563" }
}
