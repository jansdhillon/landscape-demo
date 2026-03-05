resource "lxd_cached_image" "image" {
  for_each = {
    for instance in var.lxd_vms :
    coalesce(instance.image_alias, instance.fingerprint) => instance...
  }

  source_image  = each.value.image_alias != null ? each.value.image_alias : each.value.fingerprint
  source_remote = "ubuntu"
  type          = "virtual-machine"
  copy_aliases  = false

  lifecycle {
    ignore_changes = [aliases]
  }
}

resource "lxd_instance" "vm" {
  for_each = {
    for instance in var.lxd_vms :
    instance.client_config.computer_title => instance
  }

  name  = each.value.client_config.computer_title
  image = lxd_cached_image.image[coalesce(each.value.image_alias, each.value.fingerprint)].fingerprint
  type  = "virtual-machine"

  config = each.value.additional_cloud_init != null ? {
    "cloud-init.user-data" = each.value.additional_cloud_init
  } : {}

  dynamic "device" {
    for_each = each.value.devices
    content {
      name       = device.value.name
      type       = device.value.type
      properties = device.value.properties
    }
  }

  dynamic "file" {
    for_each = each.value.files
    content {
      content            = file.value.content
      source_path        = file.value.source_path
      target_path        = file.value.target_path
      uid                = file.value.uid
      gid                = file.value.gid
      mode               = file.value.mode
      create_directories = file.value.create_directories
    }
  }

  timeouts = { create = "30m" }

  execs = merge(
    {
      "000-pro-attach" = {
        command       = ["pro", "attach", var.pro_token]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      }
      "001-add-ppa" = {
        enabled       = var.ppa != null
        command       = var.ppa != null ? ["add-apt-repository", var.ppa] : ["true"]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      }
      "002-ssl-handshake" = {
        command = [
          "/bin/bash", "-c",
          "echo | openssl s_client -connect ${var.landscape_root_url}:443 | openssl x509 > /etc/landscape/server.pem"
        ]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      }
      "003-install" = {
        command       = ["/bin/bash", "-c", "apt-get update && apt-get install -y landscape-client"]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      }
      "004-config" = {
        command = [
          "/bin/bash", "-c",
          join(" ", compact([
            "sudo landscape-config --silent",
            "--computer-title ${each.value.client_config.computer_title}",
            "--account-name ${coalesce(each.value.client_config.account_name, var.landscape_account_name)}",
            (each.value.client_config.registration_key != null && each.value.client_config.registration_key != "") || (var.registration_key != null && var.registration_key != "") ? "--registration-key ${coalesce(each.value.client_config.registration_key, var.registration_key)}" : null,
            "--url https://${var.landscape_root_url}/message-system",
            "--ping-url http://${var.landscape_root_url}/ping",
            "--ssl-public-key /etc/landscape/server.pem",
            each.value.client_config.log_level != null ? "--log-level ${each.value.client_config.log_level}" : null,
            each.value.client_config.script_users != null ? "--script-users ${each.value.client_config.script_users}" : null,
            each.value.client_config.tags != null ? "--tags ${each.value.client_config.tags}" : null,
            each.value.client_config.access_group != null ? "--access-group ${each.value.client_config.access_group}" : null,
            each.value.client_config.exchange_interval != null ? "--exchange-interval ${each.value.client_config.exchange_interval}" : null,
            each.value.client_config.urgent_exchange_interval != null ? "--urgent-exchange-interval ${each.value.client_config.urgent_exchange_interval}" : null,
            each.value.client_config.ping_interval != null ? "--ping-interval ${each.value.client_config.ping_interval}" : null,
            each.value.http_proxy != null ? "--http-proxy ${each.value.http_proxy}" : null,
            each.value.https_proxy != null ? "--https-proxy ${each.value.https_proxy}" : null,
          ]))
        ]
        trigger       = "once"
        record_output = true
        fail_on_error = true
      }
    },
    {
      for exec in each.value.execs : exec.name => {
        command       = exec.command
        enabled       = exec.enabled
        trigger       = exec.trigger
        environment   = exec.environment
        working_dir   = exec.working_dir
        record_output = exec.record_output
        fail_on_error = exec.fail_on_error
        uid           = exec.uid
        gid           = exec.gid
      }
    }
  )
}
