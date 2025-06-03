module "lxd-vm" {
  source                 = "./lxd/vm"
  lxd_vm_name            = "vulnerable"
  lxd_series             = "focal"
  registration_key       = var.registration_key
  pro_token              = var.pro_token
  landscape_fqdn         = var.landscape_fqdn
  landscape_account_name = "standalone"
}

module "ubuntu-core-device" {
  source              = "./multipass/ubuntu-core"
  registration_key    = var.registration_key
  pro_token           = var.pro_token
  landscape_fqdn      = var.landscape_fqdn
  ubuntu_core_series  = "core24"
  device_name         = "noble-core"
}

