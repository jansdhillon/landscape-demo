# Landscape Terraform provider
# Dev: build and install from ../terraform-provider-landscape with `make install`
# The ~/.terraformrc dev_overrides block points jansdhillon/landscape -> ~/go/bin
provider "landscape" {
  base_url = "https://${local.root_url}"
  email    = var.admin_email
  password = var.admin_password
}

# Welcome script — runs on every newly enrolled computer via the script profile below.
resource "landscape_script_v2" "welcome" {
  title      = "Welcome to Landscape"
  code       = <<-EOT
    #!/bin/bash
    echo "Welcome to Landscape!" | tee landscape.txt
  EOT
  username   = "root"
  time_limit = 300

  depends_on = [terraform_data.juju_wait_for_landscape]
}

# Script profile — triggers the welcome script on every new computer enrollment.
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

  depends_on = [landscape_script_v2.welcome]
}
