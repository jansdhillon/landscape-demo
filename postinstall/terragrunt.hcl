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

inputs = {
  server_ip      = dependency.deploy.outputs.server_ip
  tls_ca_cert    = run_cmd("--terragrunt-quiet", "bash", "-c", "openssl s_client -connect ${dependency.deploy.outputs.server_ip}:443 -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM || echo ''")
  admin_email    = local.r.admin_email
  admin_password = local.r.admin_password
  workspace_name = local.r.workspace_name
  domain         = local.r.domain
  smtp_host      = local.r.smtp_host
  smtp_port      = local.r.smtp_port
  smtp_username  = local.r.smtp_username
  smtp_password  = local.r.smtp_password
  gpg_key        = local.r.gpg_key_file != null ? file("${get_parent_terragrunt_dir()}/${local.r.gpg_key_file}") : null
  mirror_series  = local.r.mirror_series
}
