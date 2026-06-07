# © 2026 Canonical Ltd.

# The following outputs are meant to conform with Canonical's standards for
# charm modules in a Terraform ecosystem (CC008).

output "application" {
  description = "The deployed landscape-client application object."
  value       = juju_application.landscape_client
}

output "app_name" {
  description = "Name of the deployed application."
  value       = juju_application.landscape_client.name
}

output "requires" {
  description = "Map of integration endpoints this charm requires."
  value       = {}
}

output "provides" {
  description = "Map of integration endpoints this charm provides."
  value       = {}
}
