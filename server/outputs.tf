output "root_url" {
  value = data.external.get_haproxy_ip.result.ip_address
}
