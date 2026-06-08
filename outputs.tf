# © 2026 Canonical Ltd.

output "landscape_url" {
  description = "URL of the Landscape web interface."
  value       = "https://${var.landscape_root_url}"
}

output "model_name" {
  description = "Juju model name."
  value       = local.model.name
}

output "client_model_name" {
  description = "Juju model name for landscape-client machines."
  value       = juju_model.clients.name
}
