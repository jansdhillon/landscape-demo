module "landscape_server" {
  source = "git::https://github.com/jansdhillon/terraform-landscape-server.git//modules/landscape-scalable"

  create_model    = true
  model           = var.workspace_name
  path_to_ssh_key = var.path_to_ssh_key
  arch            = var.architecture
  domain          = var.domain
  hostname        = var.hostname
  smtp_host       = var.smtp_host
  smtp_port       = var.smtp_port
  smtp_username   = var.smtp_username
  smtp_password   = var.smtp_password

  landscape_server = {
    app_name = "landscape-server"
    channel  = var.landscape_server_channel
    base     = var.landscape_server_base
    units    = var.landscape_server_units
    config = {
      smtp_relay_host  = var.smtp_host
      admin_email      = var.admin_email
      admin_password   = var.admin_password
      admin_name       = var.admin_name
      registration_key = var.registration_key
      min_install      = var.min_install
      landscape_ppa    = var.landscape_ppa
    }
  }

  postgresql = {
    app_name = "postgresql"
    channel  = "14/stable"
    units    = var.postgresql_units
    config = {
      plugin_plpython3u_enable     = true
      plugin_ltree_enable          = true
      plugin_intarray_enable       = true
      plugin_debversion_enable     = true
      plugin_pg_trgm_enable        = true
      experimental_max_connections = 500
    }
  }

  haproxy = {
    app_name = "haproxy"
    channel  = "latest/edge"
    units    = 1
    config = {
      ssl_cert                    = var.b64_ssl_cert,
      ssl_key                     = var.b64_ssl_key
      default_timeouts            = "queue 60000, connect 5000, client 120000, server 120000"
      global_default_bind_options = "no-tlsv10"
      services                    = ""
    }
  }

  rabbitmq_server = {
    app_name = "rabbitmq-server"
    channel  = "latest/edge"
    units    = var.rabbitmq_server_units
    base     = "ubuntu@24.04"
    config = {
      consumer-timeout = 259200000
    }
  }
}

data "external" "get_haproxy_ip" {
  program = ["bash", "${path.module}/get_haproxy_ip.sh", var.workspace_name]

  depends_on = [module.landscape_server]
}

# Make REST API requests to Landscape for setup
resource "terraform_data" "setup_landscape" {
  depends_on = [module.landscape_server]

  triggers_replace = {
    haproxy_ip              = data.external.get_haproxy_ip.result.ip_address
    admin_email             = var.admin_email
    admin_password          = var.admin_password
    gpg_private_key_content = var.gpg_private_key_content
    series                  = var.lxd_series
  }

  provisioner "local-exec" {
    command = <<-EOT
    HAPROXY_IP='${self.triggers_replace.haproxy_ip}'
    ADMIN_EMAIL='${self.triggers_replace.admin_email}'
    ADMIN_PASSWORD='${self.triggers_replace.admin_password}'
    GPG_PRIVATE_KEY_CONTENT='${self.triggers_replace.gpg_private_key_content}'
    SERIES='${self.triggers_replace.series}'
    bash ${path.module}/setup_landscape.sh "$HAPROXY_IP" "$ADMIN_EMAIL" "$ADMIN_PASSWORD" "$GPG_PRIVATE_KEY_CONTENT" "$SERIES"
    EOT
  }

  lifecycle {
    # only run once
    ignore_changes = all
  }
}


module "landscape_client" {
  source                  = "./client"
  landscape_root_url      = module.landscape_server.self_signed_server ? data.external.get_haproxy_ip.result.ip_address : module.landscape_server.landscape_root_url
  landscape_account_name  = "standalone"
  registration_key        = var.registration_key
  pro_token               = var.pro_token
  ubuntu_core_series      = var.ubuntu_core_series
  ubuntu_core_count       = var.ubuntu_core_count
  ubuntu_core_device_name = var.ubuntu_core_device_name
  lxd_series              = var.lxd_series
  lxd_vm_name             = var.lxd_vm_name
  lxd_vm_count            = var.lxd_vm_count
  workspace_name          = var.workspace_name
}
