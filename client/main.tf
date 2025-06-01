module "landscape-server" {
  source = "./../server"
}

resource "local_file" "cloud_init_user_data" {
  content  = local.ls-client-cloud-init
  filename = "${path.module}/cloud-init.yaml"
}


data "lxd_image" "has_cves" {
  type         = "virtual-machine"
  fingerprint  = "fb944b6797cf"
  architecture = "x86_64"

}

resource "lxd_instance" "inst" {
  name  = "vulnerable"
  image = data.lxd_image.has_cves.fingerprint
  type  = "virtual-machine"

  config = {
    "user.user-data" = local.ls-client-cloud-init
  }

  depends_on = [module.landscape-server.juju_wait_for_model]
}

resource "multipass_instance" "inst2" {
  name           = "noble-core"
  cpus           = 1
  image          = "core24"
  cloudinit_file = local_file.cloud_init_user_data.filename

  depends_on = [module.landscape-server.juju_wait_for_model]
}
