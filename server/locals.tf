locals {
  self_signed  = var.path_to_ssl_cert == null || var.path_to_ssl_key == null || var.path_to_ssl_cert == "" || var.path_to_ssl_key == ""
  b64_ssl_key  = local.self_signed ? "" : data.external.read_ssl_key_and_cert[0].result.b64_encoded_key
  b64_ssl_cert = local.self_signed ? "" : data.external.read_ssl_key_and_cert[0].result.b64_encoded_cert
  
}
