# © 2026 Canonical Ltd.

locals {
  model = var.create_model ? juju_model.landscape[0] : data.juju_model.landscape[0]
}


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

resource "juju_offer" "landscape_server_juju_info" {
  model_uuid       = local.model.uuid
  application_name = module.landscape_server.applications.landscape_server.app_name
  endpoints        = ["juju-info"]
}

# Demo client machines
resource "juju_application" "ubuntu" {
  name        = "ubuntu"
  model_uuid  = juju_model.clients.uuid
  units       = var.landscape_client.units
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

  model_uuid = juju_model.clients.uuid
  app_name   = var.landscape_client.app_name
  channel    = var.landscape_client.channel
  revision   = var.landscape_client.revision

  config = merge(var.landscape_client.config, {
    url              = "https://${var.landscape_fqdn}/message-system"
    ping-url         = "http://${var.landscape_fqdn}/ping"
    account-name     = "standalone"
    registration-key = var.registration_key
  })

}


resource "juju_integration" "landscape_client_ubuntu" {
  model_uuid = juju_model.clients.uuid

  application {
    name     = module.landscape_client.app_name
    endpoint = "juju-info"
  }

  application {
    name     = juju_application.ubuntu.name
    endpoint = "juju-info"
  }

}

resource "juju_integration" "landscape_server_landscape_client" {
  model_uuid = juju_model.clients.uuid

  application {
    offer_url = juju_offer.landscape_server_juju_info.url
  }

  application {
    name     = module.landscape_client.app_name
    endpoint = "container"
  }
}

resource "terraform_data" "remove_landscape_server_saas" {
  triggers_replace = {
    model    = juju_model.clients.name
    saas_app = module.landscape_server.applications.landscape_server.app_name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "juju remove-saas -m ${self.triggers_replace.model} ${self.triggers_replace.saas_app} --force 2>/dev/null || true"
  }
}

resource "terraform_data" "wait_for_landscape" {
  provisioner "local-exec" {
    command = <<EOF
      juju wait-for application ${module.landscape_server.applications.landscape_server.app_name} \
      --model ${local.model.name} \
      --timeout 3600s \
      --query='forEach(units, unit => unit.workload-status=="active")'
  EOF
  }
}

data "external" "landscape_server_ip" {
  depends_on = [terraform_data.wait_for_landscape]

  program = ["bash", "-c", <<-EOT
    IP=$(juju status --model "${local.model.name}" --format=json \
      | jq -r '.applications["${var.landscape_server.app_name}"].units | to_entries[0].value["public-address"]')
    printf '{"ip":"%s"}' "$IP"
  EOT
  ]
}

resource "juju_model" "clients" {
  name = var.client_model_name

  config = {
    "cloudinit-userdata" = yamlencode({
      runcmd = [
        "grep -qF '${var.landscape_fqdn}' /etc/hosts || echo '${data.external.landscape_server_ip.result.ip} ${var.landscape_fqdn}' >> /etc/hosts"
      ]
    })
  }
}
