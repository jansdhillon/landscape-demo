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

variable "lxd_vms" {
  type = set(object({
    bus                     = optional(string, "session")
    computer_title          = string
    image_alias             = string
    account_name            = optional(string)
    registration_key        = optional(string)
    fqdn                    = optional(string)
    data_path               = optional(string, "/var/lib/landscape/client")
    http_proxy              = optional(string)
    https_proxy             = optional(string)
    log_dir                 = optional(string, "/var/log/landscape")
    log_level               = optional(string, "info")
    pid_file                = optional(string, "/var/run/landscape-client.pid")
    ping_url                = optional(string)
    include_manager_plugins = optional(string, "ScriptExecution")
    include_monitor_plugins = optional(string, "ALL")
    script_users            = optional(string, "landscape,root")
    ssl_public_key          = optional(string, "/etc/landscape/server.pem")
    tags                    = optional(string, "")
    url                     = optional(string)
    package_hash_id_url     = optional(string)
    additional_cloud_init   = optional(string)
    device = optional(object({
      name       = string
      type       = string
      properties = map(string)
    }))
  }))
}

variable "workspace_name" {
  type = string
}

variable "architecture" {
  type = string
  default = "amd64"
  description = "CPU architecture"
}
