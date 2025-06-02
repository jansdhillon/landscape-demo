resource "juju_integration" "landscape_server_rabbitmq_server" {
  model = var.model_name

  application {
    name = juju_application.landscape_server.name
  }

  application {
    name = juju_application.rabbitmq_server.name
  }

  lifecycle {
    replace_triggered_by = [
      juju_application.landscape_server.name,
      juju_application.landscape_server.model,
      juju_application.landscape_server.constraints,
      juju_application.landscape_server.charm.name,
      juju_application.landscape_server.charm.channel,
      juju_application.landscape_server.charm.revision,
      juju_application.landscape_server.config.landscape_ppa,

      juju_application.rabbitmq_server.name,
      juju_application.rabbitmq_server.model,
      juju_application.rabbitmq_server.constraints,
      juju_application.rabbitmq_server.charm.name,
      juju_application.rabbitmq_server.charm.channel,
      juju_application.rabbitmq_server.charm.revision,
    ]
  }

  depends_on = [ juju_application.landscape_server, juju_application.rabbitmq_server ]
}


resource "juju_integration" "landscape_server_haproxy" {
  model = var.model_name

  application {
    name = juju_application.landscape_server.name
  }

  application {
    name = juju_application.haproxy.name
  }

  lifecycle {
    replace_triggered_by = [
      juju_application.landscape_server.name,
      juju_application.landscape_server.model,
      juju_application.landscape_server.constraints,
      juju_application.landscape_server.charm.name,
      juju_application.landscape_server.charm.channel,
      juju_application.landscape_server.charm.revision,
      juju_application.landscape_server.config.landscape_ppa,

      juju_application.haproxy.name,
      juju_application.haproxy.model,
      juju_application.haproxy.constraints,
      juju_application.haproxy.charm.name,
      juju_application.haproxy.charm.channel,
      juju_application.haproxy.charm.revision,
      juju_application.haproxy.config.services,
      juju_application.haproxy.config.ssl_cert
    ]
  }

  depends_on = [ juju_application.landscape_server, juju_application.haproxy ]
}


resource "juju_integration" "landscape_server_postgresql" {
  model = var.model_name

  application {
    name     = juju_application.landscape_server.name
    endpoint = "db"
  }

  application {
    name     = juju_application.postgresql.name
    endpoint = "db-admin"
  }

  lifecycle {
    replace_triggered_by = [
      juju_application.landscape_server.name,
      juju_application.landscape_server.model,
      juju_application.landscape_server.constraints,
      juju_application.landscape_server.charm.name,
      juju_application.landscape_server.charm.channel,
      juju_application.landscape_server.charm.revision,
      juju_application.landscape_server.config.landscape_ppa,

      juju_application.postgresql.name,
      juju_application.postgresql.model,
      juju_application.postgresql.constraints,
      juju_application.postgresql.charm.name,
      juju_application.postgresql.charm.channel,
      juju_application.postgresql.charm.revision,
    ]
  }

  depends_on = [ juju_application.landscape_server, juju_application.postgresql ]
}

