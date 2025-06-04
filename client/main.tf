module "lxd-vm" {
  source                 = "./lxd/vm"
  lxd_vm_name            = var.lxd_vm_name
  lxd_series             = var.lxd_series
  registration_key       = var.registration_key
  pro_token              = var.pro_token
  landscape_fqdn         = var.landscape_fqdn
  landscape_account_name = var.landscape_account_name
  lxd_vm_count           = var.lxd_vm_count
}

module "ubuntu-core-device" {
  source             = "./multipass/ubuntu-core"
  registration_key   = var.registration_key
  pro_token          = var.pro_token
  landscape_fqdn     = var.landscape_fqdn
  ubuntu_core_series = var.ubuntu_core_series
  device_name        = var.device_name
  ubuntu_core_count  = var.ubuntu_core_count
  landscape_account_name = var.landscape_account_name
}

