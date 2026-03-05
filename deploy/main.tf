locals {
  model      = var.create_model ? juju_model.landscape[0] : data.juju_model.landscape[0]
  server_app = var.haproxy != null ? "haproxy" : "landscape-server"
}

data "juju_model" "landscape" {
  count = var.create_model ? 0 : 1
  name  = var.workspace_name
}

resource "juju_model" "landscape" {
  count       = var.create_model ? 1 : 0
  name        = var.workspace_name
  constraints = "arch=${var.architecture}"
}

resource "juju_ssh_key" "model_ssh_key" {
  model_uuid = local.model.uuid
  payload    = trimspace(file(var.path_to_ssh_key))
  depends_on = [local.model]
}

resource "terraform_data" "juju_wait_for_landscape" {
  depends_on = [module.landscape_server, local.model]
  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for model $MODEL_NAME --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active" || unit.workload-status == "blocked"))'
    EOT
    environment = {
      MODEL_NAME = local.model.name
    }
  }
}

module "landscape_server" {
  source = "git::https://github.com/canonical/landscape-server-operator//terraform/product/modules/landscape-scalable?ref=rev232"

  model_uuid = local.model.uuid
  depends_on = [local.model]

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

data "external" "server_ip" {
  depends_on = [terraform_data.juju_wait_for_landscape]
  program    = ["bash", "-c", "juju show-unit -m ${var.workspace_name} ${local.server_app}/0 --format=json | yq -o json '{\"ip\": (.[] | .[\"public-address\"])}'"]
}
