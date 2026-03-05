<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_juju"></a> [juju](#requirement\_juju) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.5 |
| <a name="provider_juju"></a> [juju](#provider\_juju) | 1.0.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_landscape_server"></a> [landscape\_server](#module\_landscape\_server) | git::https://github.com/canonical/landscape-server-operator//terraform/product/modules/landscape-scalable | rev240 |

## Resources

| Name | Type |
|------|------|
| [juju_model.landscape](https://registry.terraform.io/providers/juju/juju/latest/docs/resources/model) | resource |
| [juju_ssh_key.model_ssh_key](https://registry.terraform.io/providers/juju/juju/latest/docs/resources/ssh_key) | resource |
| [terraform_data.juju_wait_for_landscape](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [external_external.server_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [juju_model.landscape](https://registry.terraform.io/providers/juju/juju/latest/docs/data-sources/model) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_email"></a> [admin\_email](#input\_admin\_email) | n/a | `string` | n/a | yes |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | n/a | `string` | n/a | yes |
| <a name="input_path_to_ssh_key"></a> [path\_to\_ssh\_key](#input\_path\_to\_ssh\_key) | n/a | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | n/a | `string` | n/a | yes |
| <a name="input_admin_name"></a> [admin\_name](#input\_admin\_name) | n/a | `string` | `"Landscape Admin"` | no |
| <a name="input_architecture"></a> [architecture](#input\_architecture) | n/a | `string` | `"amd64"` | no |
| <a name="input_create_model"></a> [create\_model](#input\_create\_model) | n/a | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | n/a | `string` | `"example.com"` | no |
| <a name="input_haproxy"></a> [haproxy](#input\_haproxy) | n/a | <pre>object({<br/>    app_name    = optional(string, "haproxy")<br/>    channel     = optional(string, "latest/edge")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@22.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `null` | no |
| <a name="input_hostagent_messenger_ingress"></a> [hostagent\_messenger\_ingress](#input\_hostagent\_messenger\_ingress) | n/a | <pre>object({<br/>    app_name    = optional(string, "hostagent-messenger-ingress")<br/>    channel     = optional(string, "latest/edge")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@24.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `null` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | n/a | `string` | `"landscape"` | no |
| <a name="input_http_ingress"></a> [http\_ingress](#input\_http\_ingress) | n/a | <pre>object({<br/>    app_name    = optional(string, "http-ingress")<br/>    channel     = optional(string, "latest/edge")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@24.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `null` | no |
| <a name="input_landscape_server"></a> [landscape\_server](#input\_landscape\_server) | n/a | <pre>object({<br/>    app_name    = optional(string, "landscape-server")<br/>    channel     = optional(string, "25.10/edge")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@24.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `{}` | no |
| <a name="input_lb_certs"></a> [lb\_certs](#input\_lb\_certs) | n/a | <pre>object({<br/>    app_name    = optional(string, "lb-certs")<br/>    channel     = optional(string, "1/stable")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@24.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `{}` | no |
| <a name="input_postgresql"></a> [postgresql](#input\_postgresql) | n/a | <pre>object({<br/>    app_name    = optional(string, "postgresql")<br/>    channel     = optional(string, "16/stable")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@24.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `{}` | no |
| <a name="input_rabbitmq_server"></a> [rabbitmq\_server](#input\_rabbitmq\_server) | n/a | <pre>object({<br/>    app_name    = optional(string, "rabbitmq-server")<br/>    channel     = optional(string, "latest/edge")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@24.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `{}` | no |
| <a name="input_registration_key"></a> [registration\_key](#input\_registration\_key) | n/a | `string` | `""` | no |
| <a name="input_smtp_host"></a> [smtp\_host](#input\_smtp\_host) | n/a | `string` | `null` | no |
| <a name="input_smtp_password"></a> [smtp\_password](#input\_smtp\_password) | n/a | `string` | `""` | no |
| <a name="input_smtp_port"></a> [smtp\_port](#input\_smtp\_port) | n/a | `number` | `587` | no |
| <a name="input_smtp_username"></a> [smtp\_username](#input\_smtp\_username) | n/a | `string` | `""` | no |
| <a name="input_ubuntu_installer_attach_ingress"></a> [ubuntu\_installer\_attach\_ingress](#input\_ubuntu\_installer\_attach\_ingress) | n/a | <pre>object({<br/>    app_name    = optional(string, "ubuntu-installer-attach-ingress")<br/>    channel     = optional(string, "latest/edge")<br/>    config      = optional(map(string), {})<br/>    constraints = optional(string, "arch=amd64")<br/>    resources   = optional(map(string), {})<br/>    revision    = optional(number)<br/>    base        = optional(string, "ubuntu@24.04")<br/>    units       = optional(number, 1)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_server_ip"></a> [server\_ip](#output\_server\_ip) | n/a |
<!-- END_TF_DOCS -->