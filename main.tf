module "landscape_server" {
  source          = "./server"
  model_name      = var.workspace_name
  admin_email     = var.admin_email
  admin_password  = var.admin_password
  path_to_ssh_key = var.path_to_ssh_key
}

locals {
  root_url   = "${var.hostname}.${var.domain}"
  using_smtp = lookup(var.landscape_server.config, "smtp_password", null) != null && lookup(var.landscape_server.config, "smtp_host", null) != null && lookup(var.landscape_server.config, "smtp_username", null) != null
  model      = var.workspace_name
}

module "landscape_client" {
  source                  = "./client"
  landscape_root_url      = module.landscape_server.root_url
  landscape_account_name  = "standalone"
  registration_key        = var.registration_key
  pro_token               = var.pro_token
  ppa                     = var.landscape_ppa
  ubuntu_core_series      = var.ubuntu_core_series
  ubuntu_core_count       = var.ubuntu_core_count
  ubuntu_core_device_name = var.ubuntu_core_device_name
  workspace_name          = var.workspace_name
  lxd_vms                 = var.lxd_vms
  architecture            = var.architecture

  depends_on = [module.landscape_server]
}
