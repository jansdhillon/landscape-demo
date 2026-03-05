locals {
  using_smtp = var.smtp_host != null && var.smtp_host != ""
}

resource "terraform_data" "setup_postfix" {
  count = local.using_smtp ? 1 : 0

  triggers_replace = {
    smtp_host = var.smtp_host
    smtp_port = var.smtp_port
    smtp_user = var.smtp_username
    smtp_pass = var.smtp_password
    fqdn      = var.server_ip
    domain    = var.domain
    model     = var.workspace_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      juju scp -m '${self.triggers_replace.model}' \
        '${path.module}/../setup_postfix.sh' landscape-server/leader:/tmp/setup_postfix.sh
      juju exec -m '${self.triggers_replace.model}' --application landscape-server -- \
        "sudo chmod +x /tmp/setup_postfix.sh && /tmp/setup_postfix.sh \
          '${self.triggers_replace.smtp_host}' \
          '${self.triggers_replace.smtp_port}' \
          '${self.triggers_replace.smtp_user}' \
          '${self.triggers_replace.smtp_pass}' \
          '${self.triggers_replace.fqdn}' \
          '${self.triggers_replace.domain}'"
    EOT
  }

  lifecycle { ignore_changes = all }
}

resource "landscape_script_v2" "welcome" {
  title      = "Welcome to Landscape"
  code       = <<-EOT
    #!/bin/bash
    echo "Welcome to Landscape!" | tee landscape.txt
  EOT
  username   = "root"
  time_limit = 300
}

resource "landscape_script_profile" "welcome" {
  title         = "Welcome to Landscape"
  script_id     = landscape_script_v2.welcome.id
  username      = "root"
  time_limit    = 300
  all_computers = true
  trigger = {
    type       = "event"
    event_type = "post_enrollment"
  }
}

resource "landscape_gpg_key" "mirror" {
  count    = var.gpg_key != null ? 1 : 0
  name     = "mirror-key"
  material = var.gpg_key
}

resource "landscape_distribution" "ubuntu" {
  count      = var.gpg_key != null ? 1 : 0
  name       = "ubuntu"
  depends_on = [landscape_gpg_key.mirror]
}

resource "landscape_series" "ubuntu" {
  count         = var.gpg_key != null ? 1 : 0
  name          = var.mirror_series
  distribution  = landscape_distribution.ubuntu[0].name
  gpg_key       = landscape_gpg_key.mirror[0].name
  mirror_uri    = "http://archive.ubuntu.com/ubuntu"
  architectures = ["amd64"]
  components    = ["main", "universe", "multiverse", "restricted"]
  pockets       = ["release", "updates", "security", "proposed", "backports"]
  depends_on    = [landscape_distribution.ubuntu]
}

resource "landscape_repository_profile" "mirror" {
  count        = var.gpg_key != null ? 1 : 0
  title        = "apply-ubuntu-${var.mirror_series}-mirror"
  distribution = landscape_distribution.ubuntu[0].name
  series       = landscape_series.ubuntu[0].name
  pockets      = ["release", "updates", "security", "proposed", "backports"]
  tags         = [var.mirror_series]
  depends_on   = [landscape_series.ubuntu]
}
