resource "juju_integration" "landscape-server-rabbitmq-server" {
  model = var.model_name

  application {
    name = juju_application.landscape-server.name
  }

  application {
    name = juju_application.rabbitmq_server.name
  }

  lifecycle {
    replace_triggered_by = [
      juju_application.landscape-server.name,
      juju_application.landscape-server.model,
      juju_application.landscape-server.constraints,
      juju_application.landscape-server.charm.name,
      juju_application.landscape-server.charm.channel,
      juju_application.landscape-server.charm.revision,
      juju_application.landscape-server.config.landscape_ppa,

      juju_application.rabbitmq_server.name,
      juju_application.rabbitmq_server.model,
      juju_application.rabbitmq_server.constraints,
      juju_application.rabbitmq_server.charm.name,
      juju_application.rabbitmq_server.charm.channel,
      juju_application.rabbitmq_server.charm.revision,
    ]
  }
}


resource "juju_integration" "landscape-server-haproxy" {
  model = var.model_name

  application {
    name = juju_application.landscape-server.name
  }

  application {
    name = juju_application.haproxy.name
  }

  lifecycle {
    replace_triggered_by = [
      juju_application.landscape-server.name,
      juju_application.landscape-server.model,
      juju_application.landscape-server.constraints,
      juju_application.landscape-server.charm.name,
      juju_application.landscape-server.charm.channel,
      juju_application.landscape-server.charm.revision,
      juju_application.landscape-server.config.landscape_ppa,

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
}


resource "juju_integration" "landscape-server-postgresql" {
  model = var.model_name

  application {
    name     = juju_application.landscape-server.name
    endpoint = "db"
  }

  application {
    name     = juju_application.postgresql.name
    endpoint = "db-admin"
  }

  lifecycle {
    replace_triggered_by = [
      juju_application.landscape-server.name,
      juju_application.landscape-server.model,
      juju_application.landscape-server.constraints,
      juju_application.landscape-server.charm.name,
      juju_application.landscape-server.charm.channel,
      juju_application.landscape-server.charm.revision,
      juju_application.landscape-server.config.landscape_ppa,

      juju_application.postgresql.name,
      juju_application.postgresql.model,
      juju_application.postgresql.constraints,
      juju_application.postgresql.charm.name,
      juju_application.postgresql.charm.channel,
      juju_application.postgresql.charm.revision,
    ]
  }
}

