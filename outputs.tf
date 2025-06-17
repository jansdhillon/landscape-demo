output "haproxy_ip" {
  description = "IPv4 address of the HAProxy unit"
  value       = module.landscape_server.haproxy_ip
}

output "landscape_root_url" {
    value = module.landscape_server.landscape_root_url
}
