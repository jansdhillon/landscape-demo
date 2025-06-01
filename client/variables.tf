variable "script_users" {
  type    = string
  default = "ALL"
}

variable "access_group" {
  type    = string
  default = "global"
}

variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
}

variable "haproxy_ip" {
  type = string
}

variable "landscape_account_name" {
  type = string
}

variable "registration_key" {
  type = string
}

