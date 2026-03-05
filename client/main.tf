module "lxd" {
  source = "./lxd"

  lxd_vms                = var.lxd_vms
  landscape_root_url     = var.landscape_root_url
  landscape_account_name = var.landscape_account_name
  registration_key       = var.registration_key
  pro_token              = var.pro_token
  ppa                    = var.ppa
}

module "ubuntu-core-device" {
  source                  = "./multipass/ubuntu-core"
  registration_key        = var.registration_key
  pro_token               = var.pro_token
  landscape_root_url      = var.landscape_root_url
  ubuntu_core_series      = var.ubuntu_core_series
  ubuntu_core_device_name = var.ubuntu_core_device_name
  landscape_account_name  = var.landscape_account_name
  ubuntu_core_count       = var.ubuntu_core_count
  workspace_name          = var.workspace_name
  architecture            = var.architecture
}
