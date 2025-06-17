resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}

resource "multipass_instance" "core_device" {
  count          = var.device_name != "" ? 1 : 0
  name           = "${var.workspace_name}-${var.device_name}-${count.index}"
  image          = var.ubuntu_core_series
  cloudinit_file = local_file.cloud_init_user_data.filename
}
