output "landscape-server-postgresql" {
  value       = juju_integration.landscape-server-postgresql
}

output "haproxy_ip" {
  description = "The IP address of the first HAProxy unit."
  value       = juju_application.haproxy.units.private_address
}

output "model_name" {
    description = "Name of the Juju model"
    value = juju_model.landscape.name
}

output "landscape_account_name" {
    value = var.landscape_account_name
}

output "registration_key" {
    value = var.registration_key
}
