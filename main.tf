module "ls_server" {
  source = "./server"
  model_name = var.model_name
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

module "ls_client" {
  source = "./client"
  landscape_fqdn = module.ls_server.haproxy_ip
  landscape_account_name = module.ls_server.landscape_account_name
  registration_key = module.ls_server.registration_key
  pro_token = var.pro_token

  depends_on = [ terraform_data.juju_wait_for_ls_server ]
}



