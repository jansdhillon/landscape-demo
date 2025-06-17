locals {
  self_signed = var.b64_ssl_key == "" || var.b64_ssl_cert == ""

}
