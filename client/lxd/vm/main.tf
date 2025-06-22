resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}


data "lxd_image" "has_cves" {
  type         = "virtual-machine"
  fingerprint  = local.series_to_fingerprint[var.lxd_series]
  // TODO: make architecutre-agnostic
  architecture = "x86_64"

}

resource "lxd_instance" "lxd_vm" {
  count = var.lxd_vm_count
  name  = "${var.workspace_name}-${var.lxd_vm_name}-${count.index}"
  image = data.lxd_image.has_cves.fingerprint
  type  = "virtual-machine"

  config = {
    "user.user-data" = local.landscape_client_cloud_init
  }

  provisioner "local-exec" {
    command = <<-EOT
      lxc exec "${self.name}" --verbose -- cloud-init status --wait
    EOT
  }
}


