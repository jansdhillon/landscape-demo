# © 2026 Canonical Ltd.

variable "model_name" {
  description = "Name of the Juju model to create."
  type        = string
  default     = "landscape-demo"
}

variable "create_model" {
  description = "Set to false to use an existing model instead of creating one."
  type        = bool
  default     = true
}

variable "architecture" {
  description = "CPU architecture constraint applied to the model and all charms."
  type        = string
  default     = "amd64"
}

variable "admin_email" {
  description = "Landscape administrator email address."
  type        = string
}

variable "admin_password" {
  description = "Landscape administrator password."
  type        = string
  sensitive   = true
}

variable "admin_name" {
  description = "Landscape administrator display name."
  type        = string
  default     = "Landscape Admin"
}

variable "registration_key" {
  description = "Landscape auto-registration key."
  type        = string
  sensitive   = true
  default     = ""
}

variable "landscape_fqdn" {
  description = "Fully qualified domain name for the Landscape server (e.g. landscape.example.com). Used in both server root_url and client url config so both charms can be deployed in parallel without sequencing."
  type        = string
  default     = "landscape.local"
}

variable "landscape_server" {
  description = "Configuration overrides for the landscape-server charm."
  type = object({
    app_name    = optional(string, "landscape-server")
    channel     = optional(string, "26.04/edge")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number, 355)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default = {}
}

variable "postgresql" {
  description = "Configuration overrides for the postgresql charm. Set to null to skip."
  type = object({
    app_name    = optional(string, "postgresql")
    channel     = optional(string, "16/stable")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default  = {}
  nullable = true
}

variable "haproxy" {
  description = "Configuration overrides for the legacy HAProxy charm. Set to null for 26.04+ deployments with internal HAProxy."
  type = object({
    app_name    = optional(string, "haproxy")
    channel     = optional(string, "latest/edge")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })
  default  = null
  nullable = true
}

variable "rabbitmq_server" {
  description = "Configuration overrides for the rabbitmq-server charm. Set to null to skip."
  type = object({
    app_name    = optional(string, "rabbitmq-server")
    channel     = optional(string, "latest/edge")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default  = {}
  nullable = true
}

variable "lb_certs" {
  description = "Configuration overrides for the self-signed-certificates charm. Set to null to skip."
  type = object({
    app_name    = optional(string, "lb-certs")
    channel     = optional(string, "1/stable")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default  = {}
  nullable = true
}

variable "http_ingress" {
  description = "Configuration overrides for the http ingress-configurator charm. Set to null to skip."
  type = object({
    app_name    = optional(string, "http-ingress")
    channel     = optional(string, "latest/edge")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default  = null
  nullable = true
}

variable "hostagent_messenger_ingress" {
  description = "Configuration overrides for the hostagent-messenger ingress-configurator charm. Set to null to skip."
  type = object({
    app_name    = optional(string, "hostagent-messenger-ingress")
    channel     = optional(string, "latest/edge")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default  = null
  nullable = true
}

variable "ubuntu_installer_attach_ingress" {
  description = "Configuration overrides for the ubuntu-installer-attach ingress-configurator charm. Set to null to skip."
  type = object({
    app_name    = optional(string, "ubuntu-installer-attach-ingress")
    channel     = optional(string, "latest/edge")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default  = null
  nullable = true
}

variable "landscape_client" {
  description = "Configuration for demo landscape-client machines. Units controls how many demo client machines are created."
  type = object({
    app_name    = optional(string, "landscape-client")
    channel     = optional(string, "latest/stable")
    config      = optional(map(string), {})
    constraints = optional(string, "arch=amd64")
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 3)
  })
  default = {}
}

variable "smtp_host" {
  description = "SMTP relay hostname. Set to null to skip Postfix configuration."
  type        = string
  default     = null
  nullable    = true
}

variable "smtp_port" {
  description = "SMTP relay port."
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP relay username."
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP relay password."
  type        = string
  sensitive   = true
  default     = ""
}
