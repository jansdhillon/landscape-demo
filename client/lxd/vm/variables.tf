variable "script_users" {
  type    = string
  default = "ALL"
}

variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
}

variable "landscape_root_url" {
  type = string
  description = "Fully-qualified domain name of Landscape Server"
}

variable "landscape_account_name" {
  type = string
  description = "Account name of Landscape Server, ex. standalone"
}

variable "registration_key" {
  type = string
  description = "Registration key for Landscape Server"
}

variable "lxd_vm_name" {
  type = string
  description = "The name of the LXD VM(s)"
}

variable "lxd_series" {
  type = string
  description = "Series of the LXD VM(s)"
}

variable "lxd_vm_count" {
  type = number
}
