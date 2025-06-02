resource "local_file" "cloud_init_user_data" {
  content  = local.ls-client-cloud-init
  filename = "${path.module}/cloud-init.yaml"
}


data "lxd_image" "has_cves" {
  type         = "virtual-machine"
  fingerprint  = local.series_to_fingerprint[var.lxd_series]
  architecture = "x86_64"

}

resource "lxd_instance" "inst" {
  name  = "vulnerable"
  image = data.lxd_image.has_cves.fingerprint
  type  = "virtual-machine"

  config = {
    "user.user-data" = local.ls-client-cloud-init
  }
  count = var.lxd_vms

  provisioner "local-exec" {
    command = <<-EOT
      lxc exec vulnerable --verbose -- cloud-init status --wait
    EOT
  }
}

resource "multipass_instance" "inst2" {
  name           = "noble-core"
  cpus           = 1
  image          = "core24"
  cloudinit_file = local_file.cloud_init_user_data.filename
  count          = var.ubuntu_core_devices

  provisioner "local-exec" {
    command = <<-EOT
      multipass exec noble-core --verbose -- cloud-init status --wait
    EOT
  }
}
