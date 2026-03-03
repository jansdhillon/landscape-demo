data "juju_model" "landscape" {
  count = var.create_model ? 0 : 1
  name  = local.model
}

resource "juju_model" "landscape" {
  count       = var.create_model ? 1 : 0
  name        = local.model
  constraints = "arch=${var.architecture}"
}

resource "juju_ssh_key" "model_ssh_key" {
  model_uuid = local.model_uuid
  payload    = trimspace(file(var.path_to_ssh_key))
  depends_on = [juju_model.landscape]
}

# Wait for Landscape Server model to stabilize
resource "terraform_data" "juju_wait_for_landscape" {
  depends_on = [module.landscape_server, juju_model.landscape]
  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for model $MODEL --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active" || unit.workload-status == "blocked"))'
    EOT
    environment = {
      MODEL = local.model
    }
  }
}

module "landscape_server" {
  source = "git::https://github.com/canonical/landscape-server-operator//terraform/product/modules/landscape-scalable?ref=rev232"

  model_uuid = local.model_uuid

  depends_on = [juju_model.landscape]

  landscape_server = {
    app_name    = var.landscape_server.app_name
    channel     = var.landscape_server.channel
    base        = var.landscape_server.base
    units       = var.landscape_server.units
    constraints = var.landscape_server.constraints
    revision    = var.landscape_server.revision
    resources   = var.landscape_server.resources
    config = merge(var.landscape_server.config, {
      admin_email      = var.admin_email
      admin_password   = var.admin_password
      admin_name       = var.admin_name
      registration_key = var.registration_key
      root_url         = "https://${local.root_url}/"
    })
  }

  postgresql                      = var.postgresql
  haproxy                         = var.haproxy
  rabbitmq_server                 = var.rabbitmq_server
  lb_certs                        = var.lb_certs
  http_ingress                    = var.http_ingress
  hostagent_messenger_ingress     = var.hostagent_messenger_ingress
  ubuntu_installer_attach_ingress = var.ubuntu_installer_attach_ingress
}

# Configure Postfix SMTP relay on the Landscape Server unit
resource "terraform_data" "setup_postfix" {
  count      = local.using_smtp ? 1 : 0
  depends_on = [terraform_data.juju_wait_for_landscape]

  triggers_replace = {
    smtp_host = var.smtp_host
    smtp_port = var.smtp_port
    smtp_user = var.smtp_username
    smtp_pass = var.smtp_password
    fqdn      = local.root_url
    domain    = var.domain
    model     = local.model
  }

  provisioner "local-exec" {
    command = <<-EOT
      juju scp -m '${self.triggers_replace.model}' \
        '${path.module}/setup_postfix.sh' landscape-server/leader:/tmp/setup_postfix.sh
      juju exec -m '${self.triggers_replace.model}' --application landscape-server -- \
        "sudo chmod +x /tmp/setup_postfix.sh && /tmp/setup_postfix.sh \
          '${self.triggers_replace.smtp_host}' \
          '${self.triggers_replace.smtp_port}' \
          '${self.triggers_replace.smtp_user}' \
          '${self.triggers_replace.smtp_pass}' \
          '${self.triggers_replace.fqdn}' \
          '${self.triggers_replace.domain}'"
    EOT
  }

  lifecycle { ignore_changes = all }
}

# Landscape API setup: auto-registration preference and optional repo mirroring.
# Script and script profile are managed by the landscape provider in landscape.tf.
# NOTE: local.root_url must be resolvable — add the server IP to /etc/hosts first (see README).
resource "terraform_data" "setup_landscape" {
  depends_on = [landscape_script_profile.welcome]

  triggers_replace = {
    landscape_url  = local.root_url
    admin_email    = var.admin_email
    admin_password = var.admin_password
  }

  provisioner "local-exec" {
    command = <<-EOT
      bash '${path.module}/setup_landscape.sh' \
        '${self.triggers_replace.landscape_url}' \
        '${self.triggers_replace.admin_email}' \
        '${self.triggers_replace.admin_password}'
    EOT
  }

  lifecycle { ignore_changes = all }
}

module "landscape_client" {
  source = "./client"

  landscape_root_url      = local.root_url
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

  depends_on = [terraform_data.setup_landscape]
}

output "landscape_url" {
  description = "Landscape web portal URL (requires /etc/hosts entry — see README)."
  value       = "https://${local.root_url}/new_dashboard"
}

output "get_server_ip" {
  description = "Commands to retrieve the server IP to add to /etc/hosts."
  value       = <<-EOT
    # Pre-26.04 (external HAProxy charm):
    juju show-unit -m ${local.model} haproxy/0 | yq '."haproxy/0".public-address'
    # Landscape 26.04 LTS beta+ (internal HAProxy):
    juju show-unit -m ${local.model} landscape-server/0 | yq '."landscape-server/0".public-address'
  EOT
}
