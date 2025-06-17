module "lxd-vm" {
  source                 = "./lxd/vm"
  lxd_vm_name            = var.lxd_vm_name
  lxd_series             = var.lxd_series
  registration_key       = var.registration_key
  pro_token              = var.pro_token
  landscape_root_url     = var.landscape_root_url
  landscape_account_name = var.landscape_account_name
  lxd_vm_count           = var.lxd_vm_count
  self_signed_server     = var.self_signed_server
  workspace_name         = var.workspace_name
}

module "ubuntu-core-device" {
  source                 = "./multipass/ubuntu-core"
  registration_key       = var.registration_key
  pro_token              = var.pro_token
  landscape_root_url     = var.landscape_root_url
  ubuntu_core_series     = var.ubuntu_core_series
  device_name            = var.device_name
  landscape_account_name = var.landscape_account_name
  count                  = var.include_ubuntu_core ? 1 : 0
  self_signed_server     = var.self_signed_server
  workspace_name         = var.workspace_name
}

