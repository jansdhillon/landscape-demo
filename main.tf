module "ls_server" {
  source = "./server"
}

module "ls_client" {
  source = "./client"
  haproxy_ip = module.ls_server.haproxy_ip
  landscape_account_name = module.ls_server.landscape_account_name
  registration_key = module.ls_server.registration_key
}



