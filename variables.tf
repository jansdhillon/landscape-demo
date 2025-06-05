# Juju Model

variable "model_name" {
  description = "The Juju model name for Landscape Server"
  type        = string
  default     = "landscape"
}

variable "path_to_ssh_key" {
  description = "Path to your local SSH public key to use for the Juju model"
  type        = string
}

# Ubuntu Pro

variable "pro_token" {
  description = "Ubuntu Pro token"
  type        = string
}

# Landscape Server

variable "landscape_fqdn" {
  description = "Domain name for Landscape"
  type        = string
}

variable "admin_email" {
  description = "Email of the default admin"
  type        = string
}

variable "admin_password" {
  description = "Password of the default admin"
  type        = string
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
  type = string
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
