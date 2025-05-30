module "landscape" {
  source = "github.com/jansdhillon/landscape-demo//?ref=main"
}


resource "juju_application" "landscape-server" {
  name        = "landscape-server"
  model       = var.model_name
  units       = var.landscape_server_units
  constraints = "mem=4096"

  charm {
    name    = "landscape-server"
    channel = var.landscape_server_channel
    base    = "ubuntu@24.04"

  }

  config = {
    landscape_ppa    = var.landscape_ppa
    registration_key = var.registration_key
    admin_name       = var.admin_name
    admin_email      = var.admin_email
    admin_password   = var.admin_password
  }
}

resource "juju_application" "haproxy" {
  name  = "haproxy"
  model = var.model_name
  units = var.haproxy_units


  charm {
    name     = "haproxy"
    revision = var.haproxy_revision
    channel  = var.haproxy_channel
    base     = var.haproxy_base
  }

  expose {}

  config = {
    default_timeouts            = "queue 60000, connect 5000, client 120000, server 120000"
    global_default_bind_options = "no-tlsv10"
    services                    = ""
    ssl_cert                    = "SELFSIGNED"

  }


}

resource "juju_application" "postgresql" {
  name        = "postgresql"
  model       = var.model_name
  units       = var.postgresql_units
  constraints = "mem=2048"


  charm {
    name     = "postgresql"
    revision = var.postgresql_revision
    channel  = var.postgresql_channel
    base     = var.postgresql_base
  }

  config = {
    plugin_plpython3u_enable     = true
    plugin_ltree_enable          = true
    plugin_intarray_enable       = true
    plugin_debversion_enable     = true
    plugin_pg_trgm_enable        = true
    experimental_max_connections = 500
  }


}

resource "juju_application" "rabbitmq_server" {
  name        = "rabbitmq-server"
  model       = var.model_name
  units       = var.rabbitmq_server_units
  constraints = "mem=2048"


  charm {
    name     = "rabbitmq-server"
    revision = var.rabbitmq_server_revision
    channel  = var.rabbitmq_server_channel
    base     = var.rabbitmq_server_base
  }

  config = {
    consumer-timeout = 259200000
  }


}
