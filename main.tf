module "landscape_server" {
  source                = "./server"
  model_name            = var.model_name
  path_to_ssh_key       = var.path_to_ssh_key
  admin_email           = var.admin_email
  admin_password        = var.admin_password
  min_install           = var.min_install
  landscape_ppa         = var.landscape_ppa
  registration_key      = var.registration_key
  landscape_server_base = var.landscape_server_base
  domain                = var.domain
  hostname              = var.hostname
  path_to_ssl_cert      = var.path_to_ssl_cert
  path_to_ssl_key       = var.path_to_ssl_key
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

# Handle add/cleanup root URL to /etc/hosts
resource "terraform_data" "add_landscape_root_url_to_etc_hosts" {
  depends_on = [terraform_data.juju_wait_for_landscape_server]

  triggers_replace = {
    root_url_line = "${module.landscape_server.haproxy_ip} ${module.landscape_server.landscape_root_url}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Modifying /etc/hosts requires elevated privileges."
      if ! grep -q "${self.triggers_replace.root_url_line}" /etc/hosts; then
        echo "${self.triggers_replace.root_url_line}" | sudo tee -a /etc/hosts >/dev/null
        echo "Added '${self.triggers_replace.root_url_line}' to /etc/hosts."
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Modifying /etc/hosts requires elevated privileges."
      sudo sed -i "/^${self.triggers_replace.root_url_line}$/d" /etc/hosts
      echo "Removed '${self.triggers_replace.root_url_line}' from /etc/hosts (if it existed)."
    EOT
  }
}

# Make REST API requests to Landscape for setup
resource "terraform_data" "setup_landscape" {
  depends_on = [terraform_data.juju_wait_for_landscape_server]

  triggers_replace = {
    haproxy_ip     = module.landscape_server.haproxy_ip
    admin_email    = var.admin_email
    admin_password = var.admin_password
  }

  provisioner "local-exec" {
    command = <<-EOT
    HAPROXY_IP='${self.triggers_replace.haproxy_ip}'
    ADMIN_EMAIL='${self.triggers_replace.admin_email}'
    ADMIN_PASSWORD='${self.triggers_replace.admin_password}'
    bash ${path.module}/rest_api_requests.sh "$HAPROXY_IP" "$ADMIN_EMAIL" "$ADMIN_PASSWORD"
    EOT
  }
}


module "landscape_client" {
  source                 = "./client"
  landscape_root_url     = module.landscape_server.self_signed_server ? module.landscape_server.haproxy_ip : module.landscape_server.landscape_root_url
  landscape_account_name = module.landscape_server.landscape_account_name
  registration_key       = module.landscape_server.registration_key
  pro_token              = var.pro_token
  ubuntu_core_series     = var.ubuntu_core_series
  include_ubuntu_core    = var.include_ubuntu_core
  device_name            = var.device_name
  lxd_series             = var.lxd_series
  lxd_vm_name            = var.lxd_vm_name
  lxd_vm_count           = var.lxd_vm_count
  self_signed_server     = module.landscape_server.self_signed_server

  depends_on = [terraform_data.setup_landscape]
}

