variable "workspace_name" {
  description = "Name of the OpenTofu/Terraform workspace. It will also be used as the name of the Juju model."
  type        = string
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

<<<<<<< HEAD:variables.tf
variable "path_to_ssl_cert" {
  type        = string
  default     = ""
  description = "Path to your SSL cert, if using your own domain"
}

variable "path_to_ssl_key" {
  type        = string
  default     = ""
  description = "Path to your SSL key, if using your own domain"
=======
variable "b64_ssl_cert" {
  type = string
  default = null
  sensitive = true
}

variable "b64_ssl_key" {
  type = string
  default = null
  sensitive = true
>>>>>>> 991e9f4 (probably not worth it.):terraform/variables.tf
}

variable "b64_ssl_cert" {
  type    = string
  default = ""
}

variable "b64_ssl_key" {
  type      = string
  default   = ""
}

variable "admin_name" {
  description = "First and last name of the admin"
  type        = string
  default     = "Landscape Admin"
}

variable "admin_email" {
  description = "Email of the admin"
  type        = string
}

variable "admin_password" {
  description = "Password of the admin"
  type        = string
}

variable "min_install" {
  description = "Install recommended packages like landscape-hashids but takes longer to install"
  type        = bool
  default     = true
}

variable "landscape_ppa" {
  description = "PPA to use for the Landscape Server charm"
  type        = string
  default     = "ppa:landscape/self-hosted-beta"
}

variable "registration_key" {
  type        = string
  default     = ""
  description = "Registration key for Landscape (optional)"
}

variable "landscape_server_base" {
  type        = string
  description = "Base for the Landscape Server unit(s)"
  default     = "ubuntu@22.04"
}

variable "landscape_server_channel" {
  type        = string
  description = "Landscape Server charm channel"
  default     = "latest/stable"
}

variable "landscape_server_revision" {
  type        = number
  description = "Landscape Server charm revision"
  default     = 134
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

variable "lxd_vm_count" {
  type        = number
  description = "Number of LXD VM(s)"
}

variable "lxd_series" {
  type        = string
  default     = "jammy"
  description = "Series of LXD VM"
}

variable "lxd_vm_name" {
  type        = string
  description = "The name of the LXD VM(s)"
}

variable "path_to_gpg_private_key" {
  type        = string
  description = "Path to a GPG key. Cannot have a password."

}

variable "gpg_private_key_content" {
  type        = string
  description = "URL-encoded GPG private key content"
  default     = ""
}


variable "landscape_server_units" {
  description = "Landscape Server charm units number"
  type        = number
  default = 1
}

variable "postgresql_units" {
  type        = number
  description = "Number of PostgreSQL units for the Juju model"
  default = 1
}

variable "rabbitmq_server_units" {
  type        = number
  description = "Number of RabbitMQ Server units for the Juju model"
  default = 1
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
