# © 2026 Canonical Ltd.

data "juju_model" "landscape" {
  count = var.create_model ? 0 : 1
  name  = var.model_name
}

resource "juju_model" "landscape" {
  count       = var.create_model ? 1 : 0
  name        = var.model_name
  constraints = "arch=${var.architecture}"
}

module "landscape_server" {
  source = "git::https://github.com/canonical/landscape-server-operator//terraform/product/modules/landscape-scalable?ref=rev240"

  model_uuid = local.model.uuid

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
      root_url         = "https://${var.landscape_fqdn}/"
      autoregistration = "true"
      min_install      = "true"
    })
  }

  postgresql                      = var.postgresql
  haproxy                         = var.haproxy
  rabbitmq_server                 = var.rabbitmq_server
  lb_certs                        = var.lb_certs
  http_ingress                    = var.http_ingress
  hostagent_messenger_ingress     = var.hostagent_messenger_ingress
  ubuntu_installer_attach_ingress = var.ubuntu_installer_attach_ingress

  depends_on = [local.model]
}

# Demo client machines — each becomes a Juju machine backed by LXD in the model
resource "juju_machine" "demo_client" {
  count       = var.landscape_client.units
  model_uuid  = local.model.uuid
  base        = var.landscape_client.base
  constraints = var.landscape_client.constraints
  name        = "demo-client-${count.index}"

  depends_on = [local.model]
}

# landscape-client charm deployed on the demo machines.
# The charm handles registration retries — both server and client deploy in parallel.
# VERIFY before applying: run `juju info landscape-client` and confirm config key names
# for the server URL and account name match what is set in config below.
module "landscape_client" {
  source = "./modules/landscape-client"

  model_uuid  = local.model.uuid
  app_name    = var.landscape_client.app_name
  channel     = var.landscape_client.channel
  revision    = var.landscape_client.revision
  base        = var.landscape_client.base
  constraints = var.landscape_client.constraints
  machines    = toset([for m in juju_machine.demo_client : m.machine_id])

  config = merge(var.landscape_client.config, {
    # Config key names — verify against `juju info landscape-client` output
    # before first apply. Common variants: "landscape_url"/"url", "account_name"
    landscape_url    = "https://${var.landscape_fqdn}/message-system"
    ping_url         = "http://${var.landscape_fqdn}/ping"
    account_name     = "standalone"
    registration_key = var.registration_key
  })

  depends_on = [juju_machine.demo_client]
}

# Seed demo data via charm action.
# Rev 355 on 26.04/edge adds the add-demo-data action (landscape-server-operator PR #144).
# VERIFY: confirm the exact action name with `juju actions landscape-server` once deployed.
resource "terraform_data" "add_demo_data" {
  depends_on = [module.landscape_server]

  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for unit "${APP_NAME}/0" \
        -m "${MODEL_NAME}" \
        --timeout 3600s \
        --query='workload-status=="active" && agent-status=="idle"'
      juju run -m "${MODEL_NAME}" "${APP_NAME}/leader" add-demo-data
    EOT
    environment = {
      MODEL_NAME = local.model.name
      APP_NAME   = var.landscape_server.app_name
    }
  }

  lifecycle { ignore_changes = all }
}

# Optional: configure Postfix on landscape-server for SMTP relay
resource "terraform_data" "setup_smtp" {
  count      = var.smtp_host != null ? 1 : 0
  depends_on = [resource.terraform_data.add_demo_data]

  triggers_replace = {
    smtp_host = var.smtp_host
    smtp_port = var.smtp_port
    smtp_user = var.smtp_username
  }

  provisioner "local-exec" {
    command = <<-EOT
      juju exec -m "${MODEL_NAME}" --application "${APP_NAME}" -- bash -c "
        debconf-set-selections <<< 'postfix postfix/relayhost string ${var.smtp_host}'
        debconf-set-selections <<< 'postfix postfix/main_mailer_type string Internet Site'
        DEBIAN_FRONTEND=noninteractive apt-get install -y postfix
        postconf -e 'relayhost = [${var.smtp_host}]:${var.smtp_port}'
        postconf -e 'smtp_sasl_auth_enable = yes'
        postconf -e 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd'
        postconf -e 'smtp_sasl_security_options = noanonymous'
        postconf -e 'smtp_tls_security_level = encrypt'
        install -m 600 /dev/null /etc/postfix/sasl_passwd
        printf '%s' \"[${var.smtp_host}]:${var.smtp_port} ${var.smtp_username}:\$SMTP_PASS\" > /etc/postfix/sasl_passwd
        postmap /etc/postfix/sasl_passwd
        chmod 600 /etc/postfix/sasl_passwd.db
        systemctl restart postfix
      "
    EOT
    environment = {
      MODEL_NAME = local.model.name
      APP_NAME   = var.landscape_server.app_name
      SMTP_PASS  = var.smtp_password
    }
  }
}
