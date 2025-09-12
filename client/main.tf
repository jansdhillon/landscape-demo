module "lxd-landscape-client" {
  source             = "git::https://github.com/jansdhillon/terraform-lxd-landscape-client.git//?ref=v1.0.4"
  instances          = var.lxd_vms
  account_name       = var.landscape_account_name
  landscape_root_url = var.landscape_root_url
  registration_key   = var.registration_key
  pro_token          = var.pro_token
  ppa                = var.ppa
  instance_type      = "virtual-machine"
  architecture       = local.juju_arch_to_lxd_arch[var.architecture]
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
