terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
    multipass = {
      source  = "larstobi/multipass"
    }
  }
}

provider "lxd" {}

provider "multipass" {}

variable "PRO_TOKEN" { 
  type = string
  default = "d"
}

variable "LANDSCAPE_ACCOUNT_NAME" { 
  type = string
  default = "standalone"
}

variable "LANDSCAPE_FQDN" { 
  type = string
  default = "landscape.example.com"
}
variable "SCRIPT_USERS" { 
  type = string 
  default = "ALL"
}
variable "HTTP_PROXY" { 
  type = string 
  default = ""
}
variable "HTTPS_PROXY" { 
  type = string 
  default = ""
}
variable "ACCESS_GROUP" { 
  type = string 
  default = "global"
}
variable "REGISTRATION_KEY" { 
  type = string 
  default = "key"
}

variable "HAPROXY_IP" { 
  type = string
  default = ""
}

variable "B64_CERT" { 
  type = string
  default = ""
}

locals {
  ls-client-cloud-init = <<-EOF
#cloud-config
# focal requires `ubuntu_advantage`
ubuntu_advantage:
  token: ${var.PRO_TOKEN}
# jammy onwards ignores deprecated key `ubuntu_advantage` and uses `ubuntu_pro`
ubuntu_pro:
  token: ${var.PRO_TOKEN}
runcmd:
  # on Jammy, snap "core22" assumes unsupported features: snapd2.55.5
  - snap refresh snapd
  - pro enable livepatch || ua enable livepatch
  - systemctl stop unattended-upgrades
  - systemctl disable unattended-upgrades
  - snap install landscape-client --edge
  - |
    landscape-client.config --silent --account-name="${var.LANDSCAPE_ACCOUNT_NAME}" --computer-title="$(hostname --long)" --url "https://${var.HAPROXY_IP}/message-system" --ping-url "http://${var.HAPROXY_IP}/ping" --script-users="${var.SCRIPT_USERS}" --http-proxy="${var.HTTP_PROXY}" --https-proxy="${var.HTTPS_PROXY}" --access-group="${var.ACCESS_GROUP}" --registration-key="${var.REGISTRATION_KEY}" --ssl-public-key="base64:${var.B64_CERT}"
EOF
}

resource "local_file" "cloud_init_user_data" {
  content  = local.ls-client-cloud-init
  filename = "${path.module}/cloud-init.yaml"
}


data "lxd_image" "has_cves" {
  type = "virtual-machine"
  fingerprint = "fb944b6797cf"
  architecture = "x86_64"
  
}

resource "lxd_instance" "inst" {
  name  = "vulnerable"
  image =  data.lxd_image.has_cves.fingerprint
  type = "virtual-machine"

  config = {
    "user.user-data" = local.ls-client-cloud-init
  }
}

resource "multipass_instance" "inst2" {
  name  = "noble-core"
  cpus  = 1
  image = "core24"
  cloudinit_file = local_file.cloud_init_user_data.filename
}

