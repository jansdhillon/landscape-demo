variable "server_ip" {
  description = "Landscape Server IP address."
  type        = string
}

variable "admin_email" {
  description = "Landscape admin email."
  type        = string
}

variable "admin_password" {
  description = "Landscape admin password."
  type        = string
  sensitive   = true
}

variable "workspace_name" {
  description = "Juju model name."
  type        = string
}

variable "domain" {
  description = "Domain used for Landscape Server."
  type        = string
}

variable "smtp_host" {
  description = "SMTP relay hostname. Set to null to skip Postfix configuration."
  type        = string
  default     = null
  nullable    = true
}

variable "smtp_port" {
  description = "SMTP relay port."
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP relay username."
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP relay password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "gpg_key" {
  description = "ASCII-armored GPG private key for repository mirroring (optional)."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true

  validation {
    condition     = var.gpg_key == null || can(regex("-----BEGIN PGP PRIVATE KEY BLOCK-----", var.gpg_key))
    error_message = "gpg_key must be an ASCII-armored PGP private key (-----BEGIN PGP PRIVATE KEY BLOCK-----)."
  }
}

variable "mirror_series" {
  description = "Ubuntu series to mirror (e.g. noble, jammy)."
  type        = string
  default     = "noble"

  validation {
    condition     = var.gpg_key == null || contains(["focal", "jammy", "noble", "oracular", "plucky"], var.mirror_series)
    error_message = "mirror_series must be a valid Ubuntu series name (focal, jammy, noble, oracular, plucky)."
  }
}
