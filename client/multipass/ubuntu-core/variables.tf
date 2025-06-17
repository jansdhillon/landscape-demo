
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
}

variable "ubuntu_core_series" {
  type = string
}

variable "device_name" {
  type = string
}

variable "self_signed_server" {
  type = bool
  description = "Whether Landscape Server is using a self-signed certificate or not."
}

variable "workspace_name" {
  type = string
}
