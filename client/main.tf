locals {
  # https://documentation.ubuntu.com/lxd/latest/architectures/
  juju_arch_to_lxd_arch = { "arm64" : "aarch64", "amd64" : "x86_64", "ppc64el" : "ppc64le", "s390x" : "s390x", "riscv64" : "riscv64" }
}

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

  count = length(tolist(var.lxd_vms)) > 0 ? 1 : 0
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

  count = var.ubuntu_core_count > 0 ? 1 : 0
}
