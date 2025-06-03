resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}


data "lxd_image" "has_cves" {
  type         = "virtual-machine"
  fingerprint  = local.series_to_fingerprint[var.lxd_series]
  architecture = "x86_64"

}

resource "lxd_instance" "inst" {
  name  = var.lxd_vm_name
  image = data.lxd_image.has_cves.fingerprint
  type  = "virtual-machine"

  config = {
    "user.user-data" = local.landscape_client_cloud_init
  }

  provisioner "local-exec" {
    command = <<-EOT
      lxc exec "$INSTANCE_NAME" --verbose -- cloud-init status --wait
    EOT
    environment = {
      INSTANCE_NAME = var.lxd_vm_name
    }
  }
}


