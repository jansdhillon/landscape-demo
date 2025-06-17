variable "workspace_name" {
  description = "Name of the OpenTofu/Terraform workspace"
  type = string
}

# Juju Model

variable "path_to_ssh_key" {
  description = "Path to your local SSH public key to use for the Juju model"
  type        = string
  sensitive   = true
}

# Ubuntu Pro

variable "pro_token" {
  description = "Ubuntu Pro token"
  type        = string
  sensitive   = true
}

# Landscape Server

variable "domain" {
  type    = string
  default = "example.com"
}

variable "hostname" {
  type    = string
  default = "landscape"
}

variable "path_to_ssl_cert" {
  type = string
  default = ""
}

variable "path_to_ssl_key" {
  type = string
  default = ""
  sensitive = true
}

variable "b64_ssl_cert" {
  type = string
  default = ""
}

variable "b64_ssl_key" {
  type = string
  sensitive = true
  default = ""
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

# Landscape Client Machines

variable "ubuntu_core_series" {
  type        = string
  description = "Series of Ubuntu Core"
  default     = "core24"
}

variable "device_name" {
  type    = string
  default = ""
}

variable "include_ubuntu_core" {
  description = "Register an Ubuntu Core device"
  type        = bool
}

variable "lxd_vm_count" {
  type        = number
  description = "Number of LXD VM(s)"
}

variable "lxd_series" {
  type        = string
  default     = "jammy"
  description = "Series of LXD"
}

variable "lxd_vm_name" {
  type        = string
  description = "The name of the LXD VM(s)"
}

variable "gpg_private_key_path" {
  type = string
  sensitive   = true
}
