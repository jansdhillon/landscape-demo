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

inputs = {
  workspace_name                  = local.r.workspace_name
  architecture                    = local.r.architecture
  path_to_ssh_key                 = local.r.path_to_ssh_key
  admin_email                     = local.r.admin_email
  admin_password                  = local.r.admin_password
  admin_name                      = local.r.admin_name
  registration_key                = local.r.registration_key
  domain                          = local.r.domain
  hostname                        = local.r.hostname
  smtp_host                       = local.r.smtp_host
  smtp_port                       = local.r.smtp_port
  smtp_username                   = local.r.smtp_username
  smtp_password                   = local.r.smtp_password
  landscape_server                = local.r.landscape_server
  postgresql                      = local.r.postgresql
  haproxy                         = local.r.haproxy
  rabbitmq_server                 = local.r.rabbitmq_server
}
