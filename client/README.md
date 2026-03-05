<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lxd"></a> [lxd](#module\_lxd) | ./lxd | n/a |
| <a name="module_ubuntu-core-device"></a> [ubuntu-core-device](#module\_ubuntu-core-device) | ./multipass/ubuntu-core | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_landscape_root_url"></a> [landscape\_root\_url](#input\_landscape\_root\_url) | IP/root URL of Landscape Server | `string` | n/a | yes |
| <a name="input_lxd_vms"></a> [lxd\_vms](#input\_lxd\_vms) | n/a | <pre>set(object({<br/>    client_config = object({<br/>      account_name             = optional(string)<br/>      access_group             = optional(string)<br/>      bus                      = optional(string)<br/>      computer_title           = string<br/>      registration_key         = optional(string)<br/>      data_path                = optional(string)<br/>      log_dir                  = optional(string)<br/>      log_level                = optional(string)<br/>      pid_file                 = optional(string)<br/>      ping_url                 = optional(string)<br/>      include_manager_plugins  = optional(string)<br/>      include_monitor_plugins  = optional(string)<br/>      script_users             = optional(string)<br/>      ssl_public_key           = optional(string)<br/>      tags                     = optional(string)<br/>      url                      = optional(string)<br/>      package_hash_id_url      = optional(string)<br/>      exchange_interval        = optional(number)<br/>      urgent_exchange_interval = optional(number)<br/>      ping_interval            = optional(number)<br/>    })<br/>    fingerprint           = optional(string)<br/>    image_alias           = optional(string)<br/>    fqdn                  = optional(string)<br/>    http_proxy            = optional(string)<br/>    https_proxy           = optional(string)<br/>    additional_cloud_init = optional(string)<br/>    devices = optional(list(object({<br/>      name       = string<br/>      type       = string<br/>      properties = map(string)<br/>    })), [])<br/>    execs = optional(list(object({<br/>      name          = string<br/>      command       = list(string)<br/>      enabled       = optional(bool, true)<br/>      trigger       = optional(string, "on_change")<br/>      environment   = optional(map(string))<br/>      working_dir   = optional(string)<br/>      record_output = optional(bool, false)<br/>      fail_on_error = optional(bool, false)<br/>      uid           = optional(number, 0)<br/>      gid           = optional(number, 0)<br/>    })), [])<br/>    files = optional(list(object({<br/>      content            = optional(string)<br/>      source_path        = optional(string)<br/>      target_path        = string<br/>      uid                = optional(number)<br/>      gid                = optional(number)<br/>      mode               = optional(string, "0755")<br/>      create_directories = optional(bool, false)<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_pro_token"></a> [pro\_token](#input\_pro\_token) | Ubuntu Pro token | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | n/a | `string` | n/a | yes |
| <a name="input_architecture"></a> [architecture](#input\_architecture) | CPU architecture | `string` | `"amd64"` | no |
| <a name="input_landscape_account_name"></a> [landscape\_account\_name](#input\_landscape\_account\_name) | Account name of Landscape Server, ex. standalone | `string` | `"standalone"` | no |
| <a name="input_ppa"></a> [ppa](#input\_ppa) | PPA to use for the Landscape Server/Landscape Client | `string` | `"ppa:landscape/latest-stable"` | no |
| <a name="input_registration_key"></a> [registration\_key](#input\_registration\_key) | Registration key for Landscape Server | `string` | `""` | no |
| <a name="input_ubuntu_core_count"></a> [ubuntu\_core\_count](#input\_ubuntu\_core\_count) | n/a | `number` | `0` | no |
| <a name="input_ubuntu_core_device_name"></a> [ubuntu\_core\_device\_name](#input\_ubuntu\_core\_device\_name) | n/a | `string` | `"core-client"` | no |
| <a name="input_ubuntu_core_series"></a> [ubuntu\_core\_series](#input\_ubuntu\_core\_series) | n/a | `string` | `"core24"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->