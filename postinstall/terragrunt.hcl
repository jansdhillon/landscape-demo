include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "."

  before_hook "wait_for_landscape" {
    commands = ["apply"]
    execute  = ["bash", "-c", "IP=${dependency.deploy.outputs.server_ip}; [ \"$IP\" = \"0.0.0.0\" ] && exit 0; echo 'Waiting for Landscape login...'; until curl -skf --max-time 5 -X POST https://$IP/api/login -H 'Content-Type: application/json' -d '{\"email\":\"${local.r.admin_email}\",\"password\":\"${local.r.admin_password}\"}' | grep -q 'token'; do sleep 10; done; echo 'Landscape login ready.'"]
  }
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
  tls_ca_cert    = run_cmd("--terragrunt-quiet", "bash", "-c", "IP=${dependency.deploy.outputs.server_ip}; [ \"$IP\" = \"0.0.0.0\" ] && echo '' && exit 0; for i in $(seq 1 72); do cert=$(openssl s_client -connect \"$IP\":443 </dev/null 2>/dev/null | openssl x509 -outform PEM 2>/dev/null); [ -n \"$cert\" ] && echo \"$cert\" && exit 0; sleep 5; done; echo ''")
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
