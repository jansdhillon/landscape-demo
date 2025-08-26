module "landscape-client" {
  source  = "jansdhillon/landscape-client/lxd"
  version = "1.0.0"
  pro_token = var.pro_token
  source_image = "${var.architecture}/${var.lxd_series}"
  instance_name_prefix = "${var.workspace_name}-${var.lxd_vm_name}"
  client_config = {
    registration_key = var.registration_key
    ppa = "ppa:landscape/self-hosted-beta"
    fqdn = var.landscape_root_url
    account_name = var.landscape_account_name

  }
  count = var.lxd_vm_count
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
}
