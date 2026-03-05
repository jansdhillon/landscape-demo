locals {
  landscape_client_cloud_init = <<-EOF
#cloud-config
runcmd:
# on Jammy, snap "core22" assumes unsupported features: snapd2.55.5
  - snap refresh snapd
  - mkdir -p /var/snap/landscape-client/common/etc/
  - echo | openssl s_client -connect "${var.landscape_root_url}:443" | openssl x509 | sudo tee /var/snap/landscape-client/common/etc/server.pem
  - snap install landscape-client && snap run landscape-client.config --silent --account-name="standalone" --computer-title="$(hostname --long)" --url "https://${var.landscape_root_url}/message-system" --ping-url "http://${var.landscape_root_url}/ping" --registration-key="${var.registration_key}" --ssl-public-key="/var/snap/landscape-client/common/etc/server.pem"
EOF
}

resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}

resource "multipass_instance" "core_device" {
  count          = var.ubuntu_core_count
  name           = "${var.workspace_name}-${var.ubuntu_core_device_name}-${count.index}"
  image          = var.ubuntu_core_series
  cloudinit_file = local_file.cloud_init_user_data.filename
}
