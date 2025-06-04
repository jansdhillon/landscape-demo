resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}

resource "multipass_instance" "inst2" {
  count          = var.ubuntu_core_count
  name           = "${var.device_name}-${count.index}"
  image          = var.ubuntu_core_series
  cloudinit_file = local_file.cloud_init_user_data.filename

  # Ideally we would wait for the cloud init to finish but 
  # it will timeout, and there's no way to configure it.
  # The cloud-init will still finish.
}
