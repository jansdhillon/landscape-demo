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
  source = "git::https://github.com/canonical/landscape-server-operator//terraform/product/modules/landscape-scalable?ref=rev355"

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
      root_url         = "https://${var.landscape_root_url}/"
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
  model_uuid  = juju_model.clients.uuid
  units       = var.landscape_client.units
  constraints = var.landscape_client.constraints

  charm {
    name = "ubuntu"
    base = var.landscape_client.base
  }
}


resource "juju_application" "ubuntu_pro" {
  name       = "ubuntu-pro"
  model_uuid = juju_model.clients.uuid
  charm {
    name = "ubuntu-advantage"
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
    url              = "https://${var.landscape_root_url}/message-system"
    ping-url         = "http://${var.landscape_root_url}/ping"
    account-name     = "standalone"
    registration-key = var.registration_key
  })

  ubuntu_pro_token = var.ubuntu_pro_token

}


resource "juju_integration" "landscape_client_ubuntu" {
  model_uuid = juju_model.clients.uuid

  application {
    name     = module.landscape_client.app_name
    endpoint = "container"
  }

  application {
    name     = juju_application.ubuntu.name
    endpoint = "juju-info"
  }

}

resource "juju_integration" "ubuntu_ubuntu_pro" {
  model_uuid = juju_model.clients.uuid

  application {
    name = module.landscape_client.app_name
  }

  application {
    name = juju_application.ubuntu_pro.name
    endpoint = "juju"
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

  count = var.wait_for_landscape ? 1 : 0
}

data "external" "haproxy_ip" {
  depends_on = [terraform_data.wait_for_landscape]

  program = ["bash", "-c", <<-EOT
    IP=$(juju status --model "${local.model.name}" --format=json \
      | jq -r '.applications["${var.haproxy.app_name}"].units | to_entries[0].value["public-address"]')
    printf '{"ip":"%s"}' "$IP"
  EOT
  ]
}

resource "juju_model" "clients" {
  name = var.client_model_name

  config = {
    "cloudinit-userdata" = yamlencode({
      preruncmd = [
        "HOST=$(python3 -c \"from urllib.parse import urlparse; print(urlparse('${var.landscape_root_url}').hostname)\") && grep -qF \"$HOST\" /etc/hosts || echo \"${data.external.haproxy_ip.result.ip} $HOST\" >> /etc/hosts"
      ]
    })
  }
}
