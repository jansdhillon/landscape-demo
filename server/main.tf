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

data "external" "read_ssl_key_and_cert" {
  program = ["bash", "${path.module}/encode_ssl_key_and_cert.sh", var.path_to_ssl_key, var.path_to_ssl_cert]

  count = local.self_signed ? 0 : 1
}
