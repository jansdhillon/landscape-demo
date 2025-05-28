terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
     multipass = {
      source  = "larstobi/multipass"
      version = "~> 1.0.0"
    }
  }
}

provider "lxd" {}

provider "multipass" {}

variable "PRO_TOKEN" { type = string }

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

locals {
  ls-client-cloud-init = <<EOF
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
    - pro attach ${var.PRO_TOKEN}
    - landscape-config --silent --account-name="${var.LANDSCAPE_ACCOUNT_NAME}" --computer-title="$(hostname --long)" --url "https://${var.LANDSCAPE_FQDN}/message-system" --ping-url "http://${var.LANDSCAPE_FQDN}/ping" --script-users="${var.SCRIPT_USERS}" --http-proxy="${var.HTTP_PROXY}" --https-proxy="${var.HTTPS_PROXY}" --access-group="${var.ACCESS_GROUP}" --registration-key="${var.REGISTRATION_KEY}"
    - pro enable livepatch
  EOF
}

data "lxd_image" "vul" {
  type = "virtual-machine"
  fingerprint = "fb944b6797cf"
  architecture = "x86_64"
  
}

resource "lxd_instance" "inst" {
  name  = "vulnerable"
  image =  data.lxd_image.vul.fingerprint
  type = "virtual-machine"

  config = {
    "user.user-data" = local.ls-client-cloud-init
  }
}

# resource "multipass_instance" "inst2" {
#   name  = "noble-core"
#   cpus  = 1
#   image = "core24"
# }

