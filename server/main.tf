resource "juju_model" "landscape" {
  name = var.model_name
}

resource "juju_ssh_key" "model_ssh_key" {
  model      = var.model_name
  payload    = trimspace(file(var.path_to_ssh_key))
  depends_on = [juju_model.landscape]
}


data "external" "get_haproxy_ip" {
  program = ["bash", "${path.module}/get_haproxy_ip.sh", var.model_name]

  depends_on = [juju_application.haproxy]
}

# Wait for Landscape Server model to stabilize
resource "terraform_data" "juju_wait_for_landscape_server" {
  depends_on = [juju_model.landscape]
  provisioner "local-exec" {
    command = <<-EOT
      juju wait-for model $MODEL --timeout 3600s --query='forEach(units, unit => (unit.workload-status == "active" || unit.workload-status == "blocked"))'
    EOT
    environment = {
      MODEL = juju_model.landscape.name
    }
  }
}
