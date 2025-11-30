variable "model_name" {
  description = "The name of the Juju model."
  type        = string
}

variable "repo_mirror_series" {
  description = "The series to create the repository mirror for. Ignored unless also providing path_to_gpg_key"
  default = "noble"
}


variable "create_model" {
  description = "Create a new Juju model with the given workspace_name, otherwise use an existing model with that name"
  type        = bool
  default     = true
}


variable "path_to_ssh_key" {
  description = "Path to your local SSH public key to use for the Juju model"
  type        = string
}

variable "domain" {
  type    = string
  default = "example.com"
}

variable "hostname" {
  type    = string
  default = "landscape"
}

variable "path_to_ssl_cert" {
  type        = string
  default     = ""
  description = "Path to your SSL cert, if using your own domain"
}

variable "path_to_ssl_key" {
  type        = string
  default     = ""
  description = "Path to your SSL key, if using your own domain"
}

variable "b64_ssl_cert" {
  type    = string
  default = ""
}

variable "b64_ssl_key" {
  type    = string
  default = ""
}

variable "admin_email" {
  description = "Email of the admin"
  type        = string
}

variable "admin_password" {
  description = "Password of the admin"
  type        = string
}

variable "admin_name" {
  description = "First and last name of the admin"
  type        = string
  default     = "Landscape Admin"
}

variable "registration_key" {
  type        = string
  default     = ""
  description = "Registration key for Landscape (optional)"
}

variable "landscape_ppa" {
  description = "PPA to use for Landscape Server/Landscape Client"
  type        = string
  default     = "ppa:landscape/latest-stable"
}

variable "min_install" {
  description = "Install recommended packages like landscape-hashids but takes longer to install"
  type        = bool
  default     = true
}

variable "landscape_server" {
  type = object({
    app_name = optional(string, "landscape-server")
    channel  = optional(string, "25.10/beta")
    config = optional(map(string), {
      autoregistration = true
      landscape_ppa    = "ppa:landscape/self-hosted-beta"
      min_install      = true
    })
    constraints = optional(string, "arch=amd64")
    revision    = optional(number)
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })

  default = {}
}

variable "path_to_gpg_private_key" {
  type        = string
  description = "Path to a GPG key. Cannot have a password. Optional."
  default     = ""
}

variable "gpg_private_key_content" {
  type        = string
  description = "URL-encoded GPG private key content"
  default     = ""
}

variable "smtp_host" {
  type    = string
  default = "smtp.sendgrid.net"
}

variable "smtp_port" {
  type    = number
  default = 587
}

variable "smtp_username" {
  type    = string
  default = "apikey"
}

variable "smtp_password" {
  type        = string
  default     = ""
  description = "Often your API key. Optional unless using SMTP/custom domain."
}

variable "architecture" {
  type        = string
  default     = "amd64"
  description = "CPU architecture"
}

variable "enable_repo_mirroring" {
  type        = bool
  default     = false
  description = "Enable repository mirroring functionality. Requires GPG key."
}

variable "postgresql" {
  type = object({
    app_name = optional(string, "postgresql")
    channel  = optional(string, "14/stable")
    config = optional(map(string), {
      plugin_plpython3u_enable     = true
      plugin_ltree_enable          = true
      plugin_intarray_enable       = true
      plugin_debversion_enable     = true
      plugin_pg_trgm_enable        = true
      experimental_max_connections = 500
    })
    constraints = optional(string, "arch=amd64")
    revision    = optional(number)
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })

  default = {}
}

variable "haproxy" {
  type = object({
    app_name = optional(string, "haproxy")
    channel  = optional(string, "latest/edge")
    config = optional(map(string), {
      default_timeouts            = "queue 60000, connect 5000, client 120000, server 120000"
      global_default_bind_options = "no-tlsv10"
      services                    = ""
      ssl_cert                    = "SELFSIGNED"
    })
    constraints = optional(string, "arch=amd64")
    revision    = optional(number)
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })

  default = {}
}

variable "rabbitmq_server" {
  type = object({
    app_name = optional(string, "rabbitmq-server")
    channel  = optional(string, "latest/edge")
    config = optional(map(string), {
      consumer-timeout = 259200000
    })
    constraints = optional(string, "arch=amd64")
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })

  default = {}
}
