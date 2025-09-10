locals {
  self_signed           = lookup(var.haproxy.config, "ssl_key", null) == null || lookup(var.haproxy.config, "ssl_cert", null) == null
  root_url              = "${var.hostname}.${var.domain}"
  using_smtp            = !local.self_signed && lookup(var.landscape_server.config, "smtp_password", null) != null && lookup(var.landscape_server.config, "smtp_host", null) != null && lookup(var.landscape_server.config, "smtp_username", null) != null
  model                 = var.workspace_name
  juju_arch_to_lxd_arch = { "arm64" : "aarch64", "amd64" : "x86_64", "ppc64el" : "ppc64le", "s390x" : "s390x", "riscv64" : "riscv64" }
}
