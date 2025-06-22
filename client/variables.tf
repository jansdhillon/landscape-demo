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
  default     = ""
}

variable "ubuntu_core_count" {
  type    = number
  default = 0
}

variable "ubuntu_core_device_name" {
  type    = string
  default = "core-client"
}

variable "ubuntu_core_series" {
  type    = string
  default = "core24"
}

variable "lxd_vm_count" {
  type    = number
  default = 1
}

variable "lxd_series" {
  type    = string
  default = "jammy"
}

variable "lxd_vm_name" {
  type        = string
  description = "The name of the LXD VM"
  default     = "client"
}


variable "workspace_name" {
  type = string
}
