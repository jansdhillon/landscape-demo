
variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
}

variable "landscape_root_url" {
  type        = string
}

variable "landscape_account_name" {
  type        = string
  description = "Account name of Landscape Server"
}

variable "registration_key" {
  type        = string
  description = "Registration key for Landscape Server"
  default = ""
}

variable "ubuntu_core_count" {
  type = number
}

variable "ubuntu_core_series" {
  type = string
}

variable "ubuntu_core_device_name" {
  type = string
}

variable "workspace_name" {
  type = string
}
