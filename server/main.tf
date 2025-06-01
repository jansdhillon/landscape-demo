resource "juju_model" "landscape" {
  name       = var.model_name
  credential = var.credential_name
}

resource "juju_ssh_key" "model_ssh_key" {
  model   = var.model_name
  payload = trimspace(file(var.path_to_ssh_key))
}

resource "terraform_data" "juju_wait_for_ls_server_pg" {
  depends_on = [juju_model.landscape]
  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for model $MODEL --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active" || unit.workload-status == "blocked"))'
    EOT
    environment = {
      MODEL = module.model_name
    }
  }
}
