variable "model_name" {
  description = "The Juju model name for Landscape Server"
  type        = string
  default = "landscape"
}

variable "pro_token" {
  description = "Ubuntu Pro token"
  type = string
}

variable "path_to_ssh_key" {
  description = "Path to your local SSH public key to use for the Juju model"
  type = string
}
