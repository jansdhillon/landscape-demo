terraform {
  required_version = ">= 1.6"
  required_providers {
    juju = {
      source  = "juju/juju"
    }
    lxd = {
      source = "terraform-lxd/lxd"
    }
    multipass = {
      source  = "larstobi/multipass"
    }
  }
}
