variable "workspace_name" {
  description = "Name of the OpenTofu/Terraform workspace"
  type        = string
}

variable "path_to_ssh_key" {
  description = "Path to your local SSH public key to use for the Juju model"
  type        = string
  #sensitive   = true
}

variable "pro_token" {
  description = "Ubuntu Pro token"
  type        = string
  #sensitive   = true
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
  type    = string
  default = ""
}

variable "path_to_ssl_key" {
  type    = string
  default = ""
  #sensitive = true
}

variable "b64_ssl_cert" {
  type    = string
  default = ""
}

variable "b64_ssl_key" {
  type = string
  #sensitive = true
  default = ""
}

variable "admin_email" {
  description = "Email of the default admin"
  type        = string
}

variable "admin_password" {
  description = "Password of the default admin"
  type        = string
  #sensitive   = true
}

variable "min_install" {
  description = "Install recommended packages like landscape-hashids but takes longer to install"
  type        = bool
}

variable "landscape_ppa" {
  description = "PPA to use for the Landscape Server charm"
  type        = string
}

variable "registration_key" {
  type = string
}

variable "landscape_server_base" {
  type = string
}

variable "landscape_server_channel" {
  type = string
}

variable "landscape_server_revision" {
  type = number
}

variable "ubuntu_core_series" {
  type        = string
  description = "Series of Ubuntu Core"
  default     = "core24"
}

variable "ubuntu_core_device_name" {
  type    = string
  default = "micro"
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
  type = string
}

variable "gpg_private_key_content" {
  type        = string
  description = "URL-encoded GPG private key content"
  default     = ""
  #sensitive   = true
}


variable "landscape_server_units" {
  description = "Landscape Server charm units number"
  type        = number
}

variable "postgresql_units" {
  type = number
}

variable "rabbitmq_server_units" {
  type = number
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
  type = string
  #sensitive = true
  default = ""
}
