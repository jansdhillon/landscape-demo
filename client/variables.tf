variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
}

variable "landscape_root_url" {
  type        = string
  description = "IP/root URL of Landscape Server"
}

variable "landscape_account_name" {
  type        = string
  description = "Account name of Landscape Server, ex. standalone"
  default     = "standalone"
}

variable "registration_key" {
  type        = string
  description = "Registration key for Landscape Server"
}

variable "include_ubuntu_core" {
  type = bool
}

variable "device_name" {
  type = string
}

variable "ubuntu_core_series" {
  type = string
}

variable "lxd_vm_count" {
  type = number
}

variable "lxd_series" {
  type = string
}

variable "lxd_vm_name" {
  type        = string
  description = "The name of the LXD VM"
}


variable "workspace_name" {
  type = string
}
