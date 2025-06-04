
variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
}

variable "landscape_fqdn" {
  type        = string
  description = "Fully-qualified domain name of Landscape Server"
}

variable "landscape_account_name" {
  type        = string
  description = "Account name of Landscape Server"
}

variable "registration_key" {
  type        = string
  description = "Registration key for Landscape Server"
}

variable "ubuntu_core_series" {
  type = string
}

variable "device_name" {
  type = string
}

variable "ubuntu_core_count" {
  type = number
}
