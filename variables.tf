# Juju Model

variable "model_name" {
  description = "The Juju model name for Landscape Server"
  type        = string
  default = "landscape"
}

variable "path_to_ssh_key" {
  description = "Path to your local SSH public key to use for the Juju model"
  type = string
}

# Ubuntu Pro

variable "pro_token" {
  description = "Ubuntu Pro token"
  type = string
}

# Landscape Server

variable "landscape_fqdn" {
  description = "Domain name for Landscape"
  type = string
}

variable "admin_email" {
  description = "Email of the default admin"
  type        = string
}

variable "admin_password" {
  description = "Password of the default admin"
  type        = string
}
