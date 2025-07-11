locals {
  landscape_client_cloud_init = <<-EOF
#cloud-config
apt:
  sources:
    trunk-testing-ppa:
      source: ppa:landscape/self-hosted-beta
packages:
  - landscape-client
ubuntu_advantage:
  token: ${var.pro_token}
ubuntu_pro:
  token: ${var.pro_token}
runcmd:
# on Jammy, snap "core22" assumes unsupported features: snapd2.55.5
  - snap refresh snapd
  - pro enable livepatch || ua enable livepatch
  - systemctl stop unattended-upgrades
  - systemctl disable unattended-upgrades
  - echo | openssl s_client -connect "${var.landscape_root_url}:443" | openssl x509 | sudo tee /etc/landscape/server.pem
  - landscape-config --silent --account-name="${var.landscape_account_name}" --computer-title="$(hostname --long)" --url "https://${var.landscape_root_url}/message-system" --ping-url "http://${var.landscape_root_url}/ping" --script-users="${var.script_users}" --registration-key="${var.registration_key}" --ssl-public-key="/etc/landscape/server.pem" --tags="${var.lxd_series}"
EOF

  # Only VMs (TODO: support containers)
  series_to_fingerprint = { "jammy" : "d4104f351699896891aa4c41fb521a15a96cb9c70de0b5e83cb9067faf03833a", "focal" : "fb944b6797cf25fd4c7b8035c7e8fa0082d845032336746d94a0fb4db22bd563", "noble" : "114a1bc50c4d10b31da8c9fc91c181713acf0ce37eee13521dcfa3325e02ab84" }
  # https://documentation.ubuntu.com/lxd/latest/architectures/
  juju_arch_to_lxd_arch = { "arm64": "aarch64", "amd64": "x86_64", "ppc64el": "ppc64le", "s390x": "s390x", "riscv64": "riscv64" }
}

