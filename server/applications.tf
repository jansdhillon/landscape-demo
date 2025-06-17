resource "juju_application" "landscape_server" {
  name        = "landscape-server"
  model       = var.model_name
  units       = var.landscape_server_units
  constraints = "arch=amd64 mem=4096M"


  charm {
    name     = "landscape-server"
    channel  = var.landscape_server_channel
    base     = var.landscape_server_base
    revision = var.landscape_server_revision

  }

  config = {
    landscape_ppa    = var.landscape_ppa
    registration_key = var.registration_key
    admin_name       = var.admin_name
    admin_email      = var.admin_email
    admin_password   = var.admin_password
    min_install      = var.min_install
    # Bugged: https://warthogs.atlassian.net/browse/LNDENG-2729
    # root_url         = local.root_url
  }

  depends_on = [juju_model.landscape]
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
    ssl_cert                    = local.self_signed ? "SELFSIGNED" : var.b64_ssl_cert
    ssl_key                     = local.self_signed ? "" : var.b64_ssl_key

  }

  depends_on = [juju_model.landscape]


}

resource "juju_application" "postgresql" {
  name        = "postgresql"
  model       = var.model_name
  units       = var.postgresql_units
  constraints = "arch=amd64 mem=2048M"


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

  depends_on = [juju_model.landscape]


}

resource "juju_application" "rabbitmq_server" {
  name        = "rabbitmq-server"
  model       = var.model_name
  units       = var.rabbitmq_server_units
  constraints = "arch=amd64 mem=2048M"


  charm {
    name     = "rabbitmq-server"
    revision = var.rabbitmq_server_revision
    channel  = var.rabbitmq_server_channel
    base     = var.rabbitmq_server_base
  }

  config = {
    consumer-timeout = 259200000
  }

  depends_on = [juju_model.landscape]

}
