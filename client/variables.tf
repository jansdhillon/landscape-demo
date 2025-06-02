variable "script_users" {
  type    = string
  default = "ALL"
}

variable "access_group" {
  type    = string
  default = "global"
  description = "The access group Clients will be under"
}

variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
}

variable "landscape_fqdn" {
  type = string
  description = "Fully-qualified domain name of Landscape Server"
}

variable "landscape_account_name" {
  type = string
  description = "Account name of Landscape Server, ex. standalone"
  default = "standalone"
}

variable "registration_key" {
  type = string
  description = "Registration key for Landscape Server"
}

variable "ubuntu_core_devices" {
  type = number
  description = "The number of Ubuntu Core instances to create with Multipass"
}

variable "lxd_vms" {
  type = number
  description = "The number of LXD VMs to create"
}

variable "lxd_series" {
  type = string
  description = "Series of the LXD VM(s)"
}
