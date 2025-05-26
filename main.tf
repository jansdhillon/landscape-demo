terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
    juju = {
      version = "~> 0.11.0"
      source  = "juju/juju"
    }
     multipass = {
      source  = "larstobi/multipass"
      version = "~> 1.0.0"
    }
  }
}

provider "lxd" {}

provider "juju" {}

provider "multipass" {}


data "juju_model" "mymodel" {
  name = "tf"
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
}

resource "multipass_instance" "inst2" {
  name  = "core-device"
  cpus  = 2
  image = "core24"
}

