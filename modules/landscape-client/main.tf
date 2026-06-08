# © 2026 Canonical Ltd.

resource "juju_application" "landscape_client" {
  name       = var.app_name
  model_uuid = var.model_uuid

  charm {
    name     = "landscape-client"
    channel  = var.channel
    revision = var.revision
    base     = var.base
  }

  config      = var.config
  machines    = var.machines
}
