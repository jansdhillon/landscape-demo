# Ensure the fingerprint is copied locally
resource "terraform_data" "ensure_lxd_image" {
  triggers_replace = {
    lxd_series = var.lxd_series
    fingerprint = local.series_to_fingerprint[var.lxd_series]
    remote = "ubuntu"
  }

  provisioner "local-exec" {
    command = <<-EOT  
      echo "Ensuring LXD image is available locally..."
      
      FINGERPRINT="${local.series_to_fingerprint[var.lxd_series]}"
      
      if ! lxc image list local: --format=json | yq -r '.[].fingerprint' | grep -q "$FINGERPRINT"; then
        echo "Image not found locally, downloading from ubuntu remote..."
        lxc image copy "ubuntu:$FINGERPRINT" local:
        echo "Image downloaded successfully"
      fi
    EOT
  }
}

resource "local_file" "cloud_init_user_data" {
  content  = local.landscape_client_cloud_init
  filename = "${path.module}/cloud-init.yaml"
}

data "lxd_image" "has_cves" {
  depends_on = [terraform_data.ensure_lxd_image]
  
  type         = "virtual-machine"
  fingerprint  = local.series_to_fingerprint[var.lxd_series]
  architecture = local.juju_arch_to_lxd_arch[var.architecture]
}

resource "lxd_instance" "lxd_vm" {
  count = var.lxd_vm_count
  name  = "${var.workspace_name}-${var.lxd_vm_name}-${count.index}"
  image = data.lxd_image.has_cves.fingerprint
  type  = "virtual-machine"
  
  depends_on = [terraform_data.ensure_lxd_image]
  
  config = {
    "user.user-data" = local.landscape_client_cloud_init
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      lxc exec "${self.name}" --verbose -- cloud-init status --wait
    EOT
  }
}
