output "haproxy_ip" {
  description = "IPv4 address of the HAProxy unit"
  value       = module.landscape_server.haproxy_ip
}

output "landscape_root_url" {
  value = module.landscape_server.landscape_root_url
}

output "admin_email" {
  value = module.landscape_server.admin_email
}

output "admin_password" {
  value     = module.landscape_server.admin_password
  sensitive = true
}

output "self_signed_server" {
  description = "Landscape Server is using a self-signed certificate."
  value       = module.landscape_server.self_signed_server
  sensitive = true
}

output "registration_key" {
  description = "Registration key for Landscape"
  value       = module.landscape_server.registration_key
  sensitive = true
}

output "using_smtp" {
  description = "If Landscape Server is using SMTP or not."
  value = module.landscape_server.using_smtp
  sensitive = true
}
