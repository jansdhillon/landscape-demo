variable "workspace_name" {
  description = "Name of the OpenTofu/Terraform workspace. It will also be used as the name of the Juju model."
  type        = string
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

variable "pro_token" {
  description = "Ubuntu Pro token"
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
  description = "PPA to use for the Landscape Server charm"
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
    channel  = optional(string, "latest-stable/edge")
    config = optional(map(string), {
      autoregistration = true
    })
    constraints = optional(string, "arch=amd64")
    revision    = optional(number)
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })
}

variable "ubuntu_core_series" {
  type        = string
  description = "Series of Ubuntu Core"
  default     = "core24"
}

variable "ubuntu_core_device_name" {
  type    = string
  default = "core-client"
}

variable "ubuntu_core_count" {
  description = "Number of Ubuntu Core devices"
  type        = number
  default     = 0
}

variable "lxd_vms" {
  type = set(object({
    bus                     = optional(string, "session")
    computer_title          = string
    image_alias             = string
    account_name            = optional(string)
    registration_key        = optional(string)
    fqdn                    = optional(string)
    data_path               = optional(string, "/var/lib/landscape/client")
    http_proxy              = optional(string)
    https_proxy             = optional(string)
    log_dir                 = optional(string, "/var/log/landscape")
    log_level               = optional(string, "info")
    pid_file                = optional(string, "/var/run/landscape-client.pid")
    ping_url                = optional(string)
    include_manager_plugins = optional(string, "ScriptExecution")
    include_monitor_plugins = optional(string, "ALL")
    script_users            = optional(string, "landscape,root")
    ssl_public_key          = optional(string, "/etc/landscape/server.pem")
    tags                    = optional(string, "")
    url                     = optional(string)
    package_hash_id_url     = optional(string)
    additional_cloud_init   = optional(string)
    device = optional(object({
      name       = string
      type       = string
      properties = map(string)
    }))
  }))
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
}
