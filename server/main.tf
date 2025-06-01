resource "juju_model" "landscape" {
  name = var.model_name
}


data "external" "get_haproxy_ip" {
  program = ["bash", "${path.module}/get_haproxy_ip.sh", var.model_name]

  depends_on = [juju_application.haproxy]
}


