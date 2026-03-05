provider "landscape" {
  base_url    = "https://${var.server_ip}"
  email       = var.admin_email
  password    = var.admin_password
  tls_ca_cert = var.tls_ca_cert
}
