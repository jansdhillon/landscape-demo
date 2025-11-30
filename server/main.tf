locals {
  self_signed = lookup(var.haproxy.config, "ssl_key", null) == null || lookup(var.haproxy.config, "ssl_cert", null) == null
  root_url    = "${var.hostname}.${var.domain}"
  using_smtp  = !local.self_signed && lookup(var.landscape_server.config, "smtp_password", null) != null && lookup(var.landscape_server.config, "smtp_host", null) != null && lookup(var.landscape_server.config, "smtp_username", null) != null
  model       = var.model_name
}

resource "juju_model" "landscape" {
  count       = var.create_model ? 1 : 0
  name        = local.model
  constraints = "arch=${var.architecture}"

}

resource "juju_ssh_key" "model_ssh_key" {
  model      = local.model
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
      MODEL = var.create_model ? juju_model.landscape[0].name : local.model

    }
  }
}

module "landscape_server" {
  source = "git::https://github.com/canonical/terraform-juju-landscape.git//modules/landscape-scalable?ref=v0.1.0"

  model = juju_model.landscape[0].name

  depends_on = [juju_model.landscape]

  landscape_server = {
    app_name    = var.landscape_server.app_name
    channel     = var.landscape_server.channel
    base        = var.landscape_server.base
    units       = var.landscape_server.units
    constraints = var.landscape_server.constraints
    revision    = var.landscape_server.revision
    config = merge(var.landscape_server.config, {
      admin_email      = var.admin_email
      admin_password   = var.admin_password
      admin_name       = var.admin_name
      registration_key = var.registration_key
      landscape_ppa    = var.landscape_ppa
      min_install      = var.min_install
    })
  }

  postgresql = var.postgresql

  haproxy = var.haproxy

  rabbitmq_server = var.rabbitmq_server
}

# Setup Postfix (if configured)
resource "terraform_data" "setup_postfix" {
  depends_on = [terraform_data.juju_wait_for_landscape]

  triggers_replace = {
    smtp_host     = var.smtp_host
    smtp_port     = var.smtp_port
    smtp_username = var.smtp_username
    smtp_password = var.smtp_password
    fqdn          = local.root_url
    domain        = var.domain
  }

  provisioner "local-exec" {
    command = <<-EOT
      SMTP_HOST='${self.triggers_replace.smtp_host}'
      SMTP_PORT='${self.triggers_replace.smtp_port}'
      SMTP_USERNAME='${self.triggers_replace.smtp_username}'
      SMTP_PASSWORD='${self.triggers_replace.smtp_password}'
      FQDN='${self.triggers_replace.fqdn}'
      DOMAIN='${self.triggers_replace.domain}'
      MODEL='${local.model}'

      juju scp -m "$MODEL" "${path.module}/setup_postfix.sh" landscape-server/leader:/tmp/setup_postfix.sh
      juju exec -m "$MODEL" --application landscape-server -- \
        "sudo chmod +x /tmp/setup_postfix.sh && /tmp/setup_postfix.sh \"$SMTP_HOST\" \"$SMTP_PORT\" \"$SMTP_USERNAME\" \"$SMTP_PASSWORD\" \"$FQDN\" \"$DOMAIN\""
    EOT
  }

  lifecycle {
    ignore_changes = all
  }

  count = local.using_smtp ? 1 : 0
}

data "external" "get_haproxy_ip" {
  program = ["bash", "${path.module}/get_haproxy_ip.sh", local.model]

  depends_on = [module.landscape_server]
}

# Make REST API requests to Landscape for setup
resource "terraform_data" "setup_landscape" {
  depends_on = [terraform_data.juju_wait_for_landscape]

  triggers_replace = {
    haproxy_ip              = data.external.get_haproxy_ip.result.ip_address
    admin_email             = var.admin_email
    admin_password          = var.admin_password
    gpg_private_key_content = var.gpg_private_key_content
    series                  = var.repo_mirror_series
  }

  provisioner "local-exec" {
    command = <<-EOT
    HAPROXY_IP='${self.triggers_replace.haproxy_ip}'
    ADMIN_EMAIL='${self.triggers_replace.admin_email}'
    ADMIN_PASSWORD='${self.triggers_replace.admin_password}'
    GPG_PRIVATE_KEY_CONTENT='${self.triggers_replace.gpg_private_key_content}'
    SERIES='${self.triggers_replace.series}'

    bash ${path.module}/setup_landscape.sh "$HAPROXY_IP" "$ADMIN_EMAIL" "$ADMIN_PASSWORD" "$GPG_PRIVATE_KEY_CONTENT" "$SERIES"
    EOT
  }

  lifecycle {
    # only run once
    ignore_changes = all
  }
}
