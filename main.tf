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
      demo_data        = "true"
    })
  }

  postgresql       = var.postgresql
  haproxy          = var.haproxy
  rabbitmq_server  = var.rabbitmq_server
  tls_certificates = var.tls_certificates

}

# Demo client machines
resource "juju_application" "ubuntu" {
  name        = "ubuntu"
  count       = var.landscape_client.units
  model_uuid  = local.model.uuid
  constraints = var.landscape_client.constraints

  charm {
    name = "ubuntu"
    base = var.landscape_client.base
  }

}

# landscape-client charm deployed on the demo machines.
# The charm handles registration.
module "landscape_client" {
  source = "./modules/landscape-client"

  model_uuid = local.model.uuid
  app_name   = var.landscape_client.app_name
  channel    = var.landscape_client.channel
  revision   = var.landscape_client.revision

  config = merge(var.landscape_client.config, {
    landscape_url    = "https://${var.landscape_fqdn}/message-system"
    ping_url         = "http://${var.landscape_fqdn}/ping"
    account_name     = "standalone"
    registration_key = var.registration_key
  })

}


resource "juju_integration" "landscape_client_ubuntu" {
  model_uuid = local.model.uuid

  application {
    name     = module.landscape_client.app_name
    endpoint = "juju-info"
  }

  application {
    name     = juju_application.ubuntu[0].name
    endpoint = "juju-info"
  }

}

resource "juju_integration" "lansdcape_server_landscape_client" {
  model_uuid = local.model.uuid
  application {
    name     = module.landscape_client.app_name
    endpoint = "juju-info"
  }

  application {
    name     = module.landscape_server.applications.landscape_server.app_name
    endpoint = "juju-info"
  }

}
