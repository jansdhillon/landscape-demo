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
  sensitive   = true
}

variable "domain" {
  type    = string
  default = "example.com"
}

variable "hostname" {
  type    = string
  default = "landscape"
}

variable "admin_email" {
  description = "Email of the admin"
  type        = string
}

variable "admin_password" {
  description = "Password of the admin"
  type        = string
  sensitive   = true
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

variable "smtp_host" {
  description = "SMTP relay hostname (optional)"
  type        = string
  default     = null
}

variable "smtp_port" {
  description = "SMTP relay port"
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP relay username"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP relay password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "path_to_ssl_cert" {
  description = "Path to SSL certificate file (pre-26.04 HAProxy deployments only)"
  type        = string
  default     = null
  nullable    = true
}

variable "path_to_ssl_key" {
  description = "Path to SSL private key file (pre-26.04 HAProxy deployments only)"
  type        = string
  default     = null
  nullable    = true
}

variable "landscape_ppa" {
  description = "PPA to use for Landscape Server/Landscape Client"
  type        = string
  default     = "ppa:landscape/latest-stable"
}

variable "landscape_server" {
  type = object({
    app_name = optional(string, "landscape-server")
    channel  = optional(string, "25.10/edge")
    config = optional(map(string), {
      autoregistration               = "true"
      landscape_ppa                  = "ppa:landscape/self-hosted-beta"
      min_install                    = "true"
      enable_hostagent_messenger     = "true"
      enable_ubuntu_installer_attach = "true"
    })
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })

  default = {}
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
    client_config = object({
      account_name             = optional(string)
      access_group             = optional(string)
      bus                      = optional(string)
      computer_title           = string
      registration_key         = optional(string)
      data_path                = optional(string)
      log_dir                  = optional(string)
      log_level                = optional(string)
      pid_file                 = optional(string)
      ping_url                 = optional(string)
      include_manager_plugins  = optional(string)
      include_monitor_plugins  = optional(string)
      script_users             = optional(string)
      ssl_public_key           = optional(string)
      tags                     = optional(string)
      url                      = optional(string)
      package_hash_id_url      = optional(string)
      exchange_interval        = optional(number)
      urgent_exchange_interval = optional(number)
      ping_interval            = optional(number)
    })
    fingerprint           = optional(string)
    image_alias           = optional(string)
    fqdn                  = optional(string)
    http_proxy            = optional(string)
    https_proxy           = optional(string)
    additional_cloud_init = optional(string)
    devices = optional(list(object({
      name       = string
      type       = string
      properties = map(string)
    })), [])
    execs = optional(list(object({
      name          = string
      command       = list(string)
      enabled       = optional(bool, true)
      trigger       = optional(string, "on_change")
      environment   = optional(map(string))
      working_dir   = optional(string)
      record_output = optional(bool, false)
      fail_on_error = optional(bool, false)
      uid           = optional(number, 0)
      gid           = optional(number, 0)
    })), [])
    files = optional(list(object({
      content            = optional(string)
      source_path        = optional(string)
      target_path        = string
      uid                = optional(number)
      gid                = optional(number)
      mode               = optional(string, "0755")
      create_directories = optional(bool, false)
    })), [])
  }))

  default = []
}


variable "architecture" {
  type        = string
  default     = "amd64"
  description = "CPU architecture"
}

variable "postgresql" {
  type = object({
    app_name = optional(string, "postgresql")
    channel  = optional(string, "16/stable")
    config = optional(map(string), {
      plugin_plpython3u_enable     = "true"
      plugin_ltree_enable          = "true"
      plugin_intarray_enable       = "true"
      plugin_debversion_enable     = "true"
      plugin_pg_trgm_enable        = "true"
      experimental_max_connections = "500"
    })
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
  description = "Legacy external HAProxy charm. Set to null when using Landscape 26.04 LTS beta+ (uses internal HAProxy)."
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
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })
  default  = null
  nullable = true
}

variable "rabbitmq_server" {
  type = object({
    app_name = optional(string, "rabbitmq-server")
    channel  = optional(string, "latest/edge")
    config = optional(map(string), {
      consumer-timeout = "259200000"
    })
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
  description = "self-signed-certificates charm for internal HAProxy TLS (Landscape 26.04 LTS beta+). Set to null to skip."
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
  description = "HTTP ingress configurator charm (for external LBaaS, Landscape 26.04 LTS beta+). Set to null to skip."
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
  description = "Hostagent messenger ingress configurator charm (for external LBaaS, Landscape 26.04 LTS beta+). Set to null to skip."
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
  description = "Ubuntu installer attach ingress configurator charm (for external LBaaS, Landscape 26.04 LTS beta+). Set to null to skip."
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
