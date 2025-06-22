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
  value = module.landscape_server.admin_password
  sensitive   = true
}
