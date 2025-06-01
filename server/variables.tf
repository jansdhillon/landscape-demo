# Juju model

variable "model_name" {
  description = "The name of the Juju model to deploy Landscape to"
  type        = string
  default     = "landscape"
}

variable "create_model" {
  description = "Model creation convenience flag"
  type        = bool
  default     = false
}

variable "credential_name" {
  description = "The name of the Juju credential to use for the model"
  type        = string
  default     = null
}

variable "path_to_ssh_key" {
  description = "The path to the SSH key to use for the model"
  type        = string
  default     = "/home/jan.dhillon@canonical.com/.ssh/id_ed25519.pub"
}

# Landscape Server

variable "min_install" {
  description = "Install recommended packages like landscape-hashids but takes longer to install"
  type        = bool
  default     = true
}

variable "admin_name" {
  description = "First and last name of the default admin"
  type        = string
  default     = "Landscape Admin"
}

variable "admin_email" {
  description = "Email of the default admin"
  type        = string
  default     = "admin@example.com"
}

variable "admin_password" {
  description = "Password of the default admin"
  type        = string
  default     = "Super_secure!p@$$w0rd!"
}


variable "landscape_ppa" {
  description = "PPA to use for the Landscape Server charm"
  type        = string
  default     = "ppa:landscape/self-hosted-beta"
}

variable "landscape_server_channel" {
  description = "Landscape Server charm units number"
  type        = string
  default     = "latest/stable"
}


variable "landscape_server_units" {
  description = "Landscape Server charm units number"
  type        = number
  default     = 1
}

variable "landscape_account_name" {
  type    = string
  default = "standalone"
}

variable "landscape_fqdn" {
  type    = string
  default = "landscape.example.com"
}

variable "registration_key" {
  type    = string
  default = "key"
}

# HAProxy

variable "haproxy_ip" {
  type    = string
  default = ""
}

variable "b64_cert" {
  type    = string
  default = ""
}


variable "haproxy_units" {
  type    = number
  default = 1
}

variable "haproxy_revision" {
  type    = number
  default = 75
}

variable "haproxy_channel" {
  type    = string
  default = "latest/stable"
}

variable "haproxy_base" {
  type    = string
  default = "ubuntu@22.04"
}

# Postgres

variable "postgresql_units" {
  type    = number
  default = 2
}

variable "postgresql_revision" {
  type    = number
  default = 468
}

variable "postgresql_channel" {
  type    = string
  default = "14/stable"
}

variable "postgresql_base" {
  type    = string
  default = "ubuntu@22.04"
}

# Rabbit

variable "rabbitmq_server_units" {
  type    = number
  default = 1
}

variable "rabbitmq_server_revision" {
  type    = number
  default = 188
}

variable "rabbitmq_server_channel" {
  type    = string
  default = "3.9/stable"
}

variable "rabbitmq_server_base" {
  type    = string
  default = "ubuntu@22.04"
}

