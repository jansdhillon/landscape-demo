variable "pro_token" {
  type        = string
  description = "Ubuntu Pro token"
  sensitive   = true
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
    client_config = object({
      account_name             = optional(string)
      access_group             = optional(string)
      bus                      = optional(string)
      computer_title           = string
      registration_key         = optional(string)
      data_path                = optional(string)
      log_dir                  = optional(string)
      log_level                = optional(string)
      pid_file                 = optional(string)
      ping_url                 = optional(string)
      include_manager_plugins  = optional(string)
      include_monitor_plugins  = optional(string)
      script_users             = optional(string)
      ssl_public_key           = optional(string)
      tags                     = optional(string)
      url                      = optional(string)
      package_hash_id_url      = optional(string)
      exchange_interval        = optional(number)
      urgent_exchange_interval = optional(number)
      ping_interval            = optional(number)
    })
    fingerprint           = optional(string)
    image_alias           = optional(string)
    fqdn                  = optional(string)
    http_proxy            = optional(string)
    https_proxy           = optional(string)
    additional_cloud_init = optional(string)
    devices = optional(list(object({
      name       = string
      type       = string
      properties = map(string)
    })), [])
    execs = optional(list(object({
      name          = string
      command       = list(string)
      enabled       = optional(bool, true)
      trigger       = optional(string, "on_change")
      environment   = optional(map(string))
      working_dir   = optional(string)
      record_output = optional(bool, false)
      fail_on_error = optional(bool, false)
      uid           = optional(number, 0)
      gid           = optional(number, 0)
    })), [])
    files = optional(list(object({
      content            = optional(string)
      source_path        = optional(string)
      target_path        = string
      uid                = optional(number)
      gid                = optional(number)
      mode               = optional(string, "0755")
      create_directories = optional(bool, false)
    })), [])
  }))
}

variable "workspace_name" {
  type = string
}

variable "architecture" {
  type        = string
  default     = "amd64"
  description = "CPU architecture"
}

variable "ppa" {
  description = "PPA to use for the Landscape Server/Landscape Client"
  type        = string
  default     = "ppa:landscape/latest-stable"
}
