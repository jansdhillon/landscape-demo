module "ls_server" {
  source           = "./server"
  model_name       = var.model_name
  path_to_ssh_key  = var.path_to_ssh_key
  landscape_fqdn   = var.landscape_fqdn
  admin_email      = var.admin_email
  admin_password   = var.admin_password
  min_install      = var.min_install
  landscape_ppa    = var.landscape_ppa
  registration_key = var.registration_key
}

# Wait for Landscape Server model to stabilize
resource "terraform_data" "juju_wait_for_ls_server" {
  depends_on = [module.ls_server.model_name]
  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for model $MODEL --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active" || unit.workload-status == "blocked"))'
    EOT
    environment = {
      MODEL = module.ls_server.model_name
    }
  }
}

# Handle add/cleanup FQDN to /etc/hosts
resource "terraform_data" "add_landscape_fqdn_to_etc_hosts" {
  depends_on = [terraform_data.juju_wait_for_ls_server]

  triggers_replace = {
    fqdn_line = "${module.ls_server.haproxy_ip} ${module.ls_server.landscape_fqdn}"
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
resource "terraform_data" "landscape_configure" {
  depends_on = [terraform_data.juju_wait_for_ls_server]

  triggers_replace = {
    haproxy_ip     = module.ls_server.haproxy_ip
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


module "ls_client" {
  source                 = "./client"
  landscape_fqdn         = module.ls_server.haproxy_ip
  landscape_account_name = module.ls_server.landscape_account_name
  registration_key       = module.ls_server.registration_key
  pro_token              = var.pro_token
  lxd_vms                = 1
  ubuntu_core_devices    = 1
  lxd_series             = "focal"

  depends_on = [terraform_data.landscape_configure]
}

