variable "workspace_name" {
  type = string
}

variable "create_model" {
  type    = bool
  default = true
}

variable "architecture" {
  type    = string
  default = "amd64"
}

variable "path_to_ssh_key" {
  type = string
}

variable "admin_email" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "admin_name" {
  type    = string
  default = "Landscape Admin"
}

variable "registration_key" {
  type    = string
  default = ""
}

variable "domain" {
  type    = string
  default = "example.com"
}

variable "hostname" {
  type    = string
  default = "landscape"
}

variable "smtp_host" {
  type     = string
  default  = null
  nullable = true
}

variable "smtp_port" {
  type    = number
  default = 587
}

variable "smtp_username" {
  type    = string
  default = ""
}

variable "smtp_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "landscape_server" {
  type = object({
    app_name = optional(string, "landscape-server")
    channel  = optional(string, "24.04/beta")
    config = optional(map(string), {
      autoregistration = "true"
      landscape_ppa    = "ppa:landscape/self-hosted-24.04"
      min_install      = "true"
    })
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })
  default = {}
}

variable "postgresql" {
  type = object({
    app_name = optional(string, "postgresql")
    channel  = optional(string, "14/stable")
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
    base        = optional(string, "ubuntu@22.04")
    units       = optional(number, 1)
  })
  default  = {}
  nullable = true
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
  type = object({
    app_name = optional(string, "http-ingress")
    channel  = optional(string, "latest/edge")
    config = optional(map(string), {
      paths                      = "/"
      hostname                   = "landscape.local"
      header-rewrite-expressions = "X-Forwarded-Proto:https"
      allow-http                 = "true"
    })
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
  type = object({
    app_name = optional(string, "hostagent-messenger-ingress")
    channel  = optional(string, "latest/edge")
    config = optional(map(string), {
      external-grpc-port = "6554"
      hostname           = "landscape.local"
      backend-protocol   = "https"
    })
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
  type = object({
    app_name = optional(string, "ubuntu-installer-attach-ingress")
    channel  = optional(string, "latest/edge")
    config = optional(map(string), {
      external-grpc-port = "50051"
      hostname           = "landscape.local"
      backend-protocol   = "https"
    })
    constraints = optional(string, "arch=amd64")
    resources   = optional(map(string), {})
    revision    = optional(number)
    base        = optional(string, "ubuntu@24.04")
    units       = optional(number, 1)
  })
  default  = null
  nullable = true
}
