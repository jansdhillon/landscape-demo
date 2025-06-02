output "haproxy_ip" {
  description = "IPv4 address of the HAProxy unit"
  value       = data.external.get_haproxy_ip.result.ip_address
}

output "model_name" {
  description = "Name of the Juju model"
  value       = juju_model.landscape.name
}

output "landscape_account_name" {
  value = "standalone"
}

output "registration_key" {
  value = var.registration_key
}

output "landscape_fqdn" {
  value = var.landscape_fqdn

}
