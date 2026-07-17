# © 2026 Canonical Ltd.

terraform {
  required_version = ">= 1.0"

  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}
