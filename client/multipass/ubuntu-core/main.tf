resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}

resource "multipass_instance" "inst2" {
  name           = var.device_name
  cpus           = 1
  image          = var.ubuntu_core_series
  cloudinit_file = local_file.cloud_init_user_data.filename

  provisioner "local-exec" {
    command = <<-EOT
      multipass exec "$DEVICE_NAME" --verbose -- cloud-init status --wait
    EOT
    environment = {
      DEVICE_NAME = var.device_name
    }
  }
}
