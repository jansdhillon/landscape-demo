terraform {
  required_version = ">= 1.10"
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 1.0"
    }
    landscape = {
      source  = "jansdhillon/landscape"
      version = "~> 0.1.1"
    }
  }
}
