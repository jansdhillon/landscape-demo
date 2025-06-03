locals {
  landscape_client_cloud_init = <<-EOF
    #cloud-config
    package_update: false
    packages: []
    runcmd:
      - snap refresh snapd
      - systemctl stop unattended-upgrades
      - systemctl disable unattended-upgrades
      - mkdir -p /var/snap/landscape-client/common/etc/
      - pro attach ${var.pro_token}
      - echo | openssl s_client -connect "${var.landscape_fqdn}:443" | openssl x509 | sudo tee /var/snap/landscape-client/common/etc/server.pem
      - |
        snap install landscape-client

        until snap services | grep -q "landscape-client.*active"; do
          echo "Waiting for landscape-client service to be active..."
          sleep 5
        done

        landscape-client.config --silent \
          --account-name="${var.landscape_account_name}" \
          --computer-title="$(hostname --long)" \
          --url "https://${var.landscape_fqdn}/message-system" \
          --ping-url "http://${var.landscape_fqdn}/ping" \
          --registration-key="${var.registration_key}" \
          --ssl-public-key="/var/snap/landscape-client/common/etc/server.pem"
  EOF
}
