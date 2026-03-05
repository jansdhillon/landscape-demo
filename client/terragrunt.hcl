include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "."
}

locals {
  r = include.root.locals
}

dependency "deploy" {
  config_path = "../deploy"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs = {
    server_ip = "0.0.0.0"
  }
}

dependencies {
  paths = ["../postinstall"]
}

inputs = {
  landscape_root_url      = dependency.deploy.outputs.server_ip
  landscape_account_name  = "standalone"
  registration_key        = local.r.registration_key
  pro_token               = local.r.pro_token
  ppa                     = local.r.client_ppa
  lxd_vms                 = local.r.lxd_vms
  ubuntu_core_series      = local.r.ubuntu_core_series
  ubuntu_core_count       = local.r.ubuntu_core_count
  ubuntu_core_device_name = local.r.ubuntu_core_device_name
  workspace_name          = local.r.workspace_name
  architecture            = local.r.architecture
}
