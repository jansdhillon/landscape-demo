module "landscape_server" {
  source                = "./server"
  model_name            = var.model_name
  path_to_ssh_key       = var.path_to_ssh_key
  landscape_fqdn        = var.landscape_fqdn
  admin_email           = var.admin_email
  admin_password        = var.admin_password
  min_install           = var.min_install
  landscape_ppa         = var.landscape_ppa
  registration_key      = var.registration_key
  landscape_server_base = var.landscape_server_base
}

# Wait for Landscape Server model to stabilize
resource "terraform_data" "juju_wait_for_landscape_server" {
  depends_on = [module.landscape_server.model_name]
  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for model $MODEL --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active" || unit.workload-status == "blocked"))'
    EOT
    environment = {
      MODEL = module.landscape_server.model_name
    }
  }
}

# Handle add/cleanup FQDN to /etc/hosts
resource "terraform_data" "add_landscape_fqdn_to_etc_hosts" {
  depends_on = [terraform_data.juju_wait_for_landscape_server]

  triggers_replace = {
    fqdn_line = "${module.landscape_server.haproxy_ip} ${module.landscape_server.landscape_fqdn}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Modifying /etc/hosts requires elevated privileges."
      if ! grep -q "${self.triggers_replace.fqdn_line}" /etc/hosts; then
        echo "${self.triggers_replace.fqdn_line}" | sudo tee -a /etc/hosts >/dev/null
        echo "Added '${self.triggers_replace.fqdn_line}' to /etc/hosts."
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Modifying /etc/hosts requires elevated privileges."
      sudo sed -i "/^${self.triggers_replace.fqdn_line}$/d" /etc/hosts
      echo "Removed '${self.triggers_replace.fqdn_line}' from /etc/hosts (if it existed)."
    EOT
  }
}

# Make REST API requests to Landscape for setup
resource "terraform_data" "setup_landscape" {
  depends_on = [terraform_data.juju_wait_for_landscape_server]

  triggers_replace = {
    haproxy_ip      = module.landscape_server.haproxy_ip
    admin_email     = var.admin_email
    admin_password  = var.admin_password
    script_path     = var.script_path
    gpg_key_path    = var.gpg_key_path
    apt_source_line = var.apt_line != "" ? var.apt_line : local.apt_line
    series          = var.lxd_series
  }

  provisioner "local-exec" {
    command = <<-EOT
    HAPROXY_IP='${self.triggers_replace.haproxy_ip}'
    ADMIN_EMAIL='${self.triggers_replace.admin_email}'
    ADMIN_PASSWORD='${self.triggers_replace.admin_password}'
    SCRIPT_PATH='${self.triggers_replace.script_path}'
    GPG_KEY_PATH='${self.triggers_replace.gpg_key_path}'
    APT_SOURCE_LINE='${self.triggers_replace.apt_source_line}'
    SERIES='${self.triggers_replace.series}'
    bash ${path.module}/rest_api_requests.sh "$HAPROXY_IP" "$ADMIN_EMAIL" "$ADMIN_PASSWORD" "$SCRIPT_PATH" "$GPG_KEY_PATH" "$APT_LINE" "$SERIES"
    EOT
  }
}


module "landscape_client" {
  source                 = "./client"
  landscape_fqdn         = module.landscape_server.haproxy_ip
  landscape_account_name = module.landscape_server.landscape_account_name
  registration_key       = module.landscape_server.registration_key
  pro_token              = var.pro_token
  ubuntu_core_series     = var.ubuntu_core_series
  device_name            = var.device_name
  lxd_series             = var.lxd_series
  lxd_vm_name            = var.lxd_vm_name
  lxd_vm_count           = var.lxd_vm_count


  depends_on = [terraform_data.setup_landscape]
}

