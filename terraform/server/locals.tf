locals {
  self_signed  = var.b64_ssl_key == null || var.b64_ssl_cert == null || var.b64_ssl_key == "" || var.b64_ssl_cert == ""
  
}
