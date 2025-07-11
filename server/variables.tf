# Juju model

variable "model_name" {
  description = "The name of the Juju model to deploy Landscape Server to"
  type        = string
}


variable "path_to_ssh_key" {
  description = "The path to the SSH key to use for the model"
  type        = string
}

# Landscape Server

variable "min_install" {
  description = "Install recommended packages like landscape-hashids but takes longer to install"
  type        = bool
}

variable "admin_name" {
  description = "First and last name of the default admin"
  type        = string
  default     = "Landscape Admin"
}

variable "admin_email" {
  description = "Email of the default admin"
  type        = string
}

variable "admin_password" {
  description = "Password of the default admin"
  type        = string
  sensitive   = true
}

variable "landscape_ppa" {
  description = "PPA to use for the Landscape Server charm"
  type        = string
}

variable "landscape_server_channel" {
  type    = string
  default = "latest/stable"
}


variable "landscape_server_base" {
  type = string
}

variable "landscape_server_units" {
  description = "Landscape Server charm units number"
  type        = number
  default     = 1
}

variable "domain" {
  type    = string
  default = "landscape"
}

variable "hostname" {
  type    = string
  default = "example.com"
}

variable "b64_ssl_cert" {
  type      = string
  sensitive = true
  default   = ""
}

variable "b64_ssl_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "registration_key" {
  type    = string
  default = ""
}

variable "landscape_server_revision" {
  type    = number
  default = 134
}

# HAProxy

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
  default = 1
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

variable "smtp_host" {
  type    = string
  default = ""
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
  sensitive = true
  default   = ""
}

variable "arch" {
  type = string
  default = "amd64"
  description = "CPU architecture"
}
