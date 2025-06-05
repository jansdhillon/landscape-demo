resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}

resource "multipass_instance" "inst2" {
  name           = "${var.device_name}"
  image          = var.ubuntu_core_series
  cloudinit_file = local_file.cloud_init_user_data.filename
}
