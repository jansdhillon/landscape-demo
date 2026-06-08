# © 2026 Canonical Ltd.

variable "app_name" {
  description = "Name of the application in the Juju model."
  type        = string
  default     = "landscape-client"
}

variable "channel" {
  description = "Channel to use when deploying the charm."
  type        = string
  default     = "latest/stable"
}

variable "config" {
  description = "Application config. See https://charmhub.io/landscape-client/configurations."
  type        = map(string)
  default     = {}
}

variable "model_uuid" {
  description = "UUID of the Juju model to deploy into. Not nullable."
  type        = string
}

variable "revision" {
  description = "Revision number of the charm. Null deploys the latest on the given channel."
  type        = number
  default     = null
  nullable    = true
}

variable "base" {
  description = "The operating system on which to deploy (e.g. ubuntu@24.04)."
  type        = string
  default     = "ubuntu@24.04"
}


variable "machines" {
  description = "Set of Juju machine IDs to place units on. When set, 'units' is ignored."
  type        = set(string)
  default     = null
  nullable    = true
}

variable "ubuntu_pro_token" {
  description = "Ubuntu Pro token. Required to register with Landscape Server."
  type        = string
  sensitive   = true
}
