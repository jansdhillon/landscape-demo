locals {
  model        = var.workspace_name
  model_uuid   = var.create_model ? juju_model.landscape[0].uuid : data.juju_model.landscape[0].uuid
  root_url     = "${var.hostname}.${var.domain}"
  using_smtp   = var.smtp_host != null && var.smtp_host != ""
}
