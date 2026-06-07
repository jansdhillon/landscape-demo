# © 2026 Canonical Ltd.

locals {
  model = var.create_model ? juju_model.landscape[0] : data.juju_model.landscape[0]
}
