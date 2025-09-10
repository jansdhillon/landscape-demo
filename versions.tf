terraform {
  required_version = ">= 1.10"
  required_providers {
    juju = {
      source  = "juju/juju"
      version = ">=0.18.0"
    }
  }
}
