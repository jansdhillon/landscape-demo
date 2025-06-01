resource "local_file" "cloud_init_user_data" {
  content  = local.ls-client-cloud-init
  filename = "${path.module}/cloud-init.yaml"
}


data "lxd_image" "has_cves" {
  type         = "virtual-machine"
  fingerprint  = "fb944b6797cf25fd4c7b8035c7e8fa0082d845032336746d94a0fb4db22bd563"
  architecture = "x86_64"

}

resource "lxd_instance" "inst" {
  name  = "vulnerable"
  image = data.lxd_image.has_cves.fingerprint
  type  = "virtual-machine"

  config = {
    "user.user-data" = local.ls-client-cloud-init
  }
}

resource "multipass_instance" "inst2" {
  name           = "noble-core"
  cpus           = 1
  image          = "core24"
  cloudinit_file = local_file.cloud_init_user_data.filename
}
