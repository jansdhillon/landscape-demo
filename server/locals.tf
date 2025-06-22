locals {
  self_signed = var.b64_ssl_key == "" || var.b64_ssl_cert == ""
  root_url = "${var.hostname}.${var.domain}"
  using_smtp = var.smtp_password != "" && var.smtp_host != "" && var.smtp_username != ""
}
