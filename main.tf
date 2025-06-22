module "landscape_server" {
  source                   = "./server"
  model_name               = var.workspace_name
  path_to_ssh_key          = var.path_to_ssh_key
  admin_email              = var.admin_email
  admin_password           = var.admin_password
  min_install              = var.min_install
  landscape_ppa            = var.landscape_ppa
  registration_key         = var.registration_key
  landscape_server_base    = var.landscape_server_base
  domain                   = var.domain
  hostname                 = var.hostname
  b64_ssl_cert             = var.b64_ssl_cert
  b64_ssl_key              = var.b64_ssl_key
  landscape_server_units   = var.landscape_server_units
  postgresql_units         = var.postgresql_units
  rabbitmq_server_units    = var.rabbitmq_server_units
  landscape_server_channel = var.landscape_server_channel
  smtp_host                = var.smtp_host
  smtp_password            = var.smtp_password
  smtp_port                = var.smtp_port
  smtp_username            = var.smtp_username
}

# Make REST API requests to Landscape for setup
resource "terraform_data" "setup_landscape" {
  depends_on = [module.landscape_server]

  triggers_replace = {
    haproxy_ip              = module.landscape_server.haproxy_ip
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
  landscape_root_url      = module.landscape_server.self_signed_server ? module.landscape_server.haproxy_ip : module.landscape_server.landscape_root_url
  landscape_account_name  = module.landscape_server.landscape_account_name
  registration_key        = module.landscape_server.registration_key
  pro_token               = var.pro_token
  ubuntu_core_series      = var.ubuntu_core_series
  ubuntu_core_count       = var.ubuntu_core_count
  ubuntu_core_device_name = var.ubuntu_core_device_name
  lxd_series              = var.lxd_series
  lxd_vm_name             = var.lxd_vm_name
  lxd_vm_count            = var.lxd_vm_count
  workspace_name          = var.workspace_name
}

