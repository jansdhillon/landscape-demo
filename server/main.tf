resource "juju_model" "landscape" {
  name = var.model_name

  provisioner "local-exec" {
    command = <<-EOT
      juju switch $MODEL
    EOT
    environment = {
      MODEL = juju_model.landscape.name
    }
  }
}

resource "juju_ssh_key" "model_ssh_key" {
  model      = var.model_name
  payload    = trimspace(file(var.path_to_ssh_key))
  depends_on = [juju_model.landscape]
}


data "external" "get_haproxy_ip" {
  program = ["bash", "${path.module}/get_haproxy_ip.sh", var.model_name]

  depends_on = [juju_application.haproxy]
}

# Wait for Landscape Server model to stabilize
resource "terraform_data" "juju_wait_for_landscape_server" {
  depends_on = [juju_model.landscape]
  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for model $MODEL --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active" || unit.workload-status == "blocked"))'
    EOT
    environment = {
      MODEL = juju_model.landscape.name
    }
  }
}

# Setup Postfix (if configured)
resource "terraform_data" "setup_postfix" {
  depends_on = [terraform_data.juju_wait_for_landscape_server]

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
      MODEL='${var.model_name}'

      juju scp -m "$MODEL" "${path.module}/setup_postfix.sh" landscape-server/leader:/tmp/setup_postfix.sh
      juju exec -m "$MODEL" --application landscape-server -- \
        "sudo chmod +x /tmp/setup_postfix.sh && /tmp/setup_postfix.sh \"$SMTP_HOST\" \"$SMTP_PORT\" \"$SMTP_USERNAME\" \"$SMTP_PASSWORD\" \"$FQDN\" \"$DOMAIN\""
    EOT
  }

  lifecycle {
    # only run once
    ignore_changes = all
  }

  count = local.using_smtp ? 1 : 0
}


