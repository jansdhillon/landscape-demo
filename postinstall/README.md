<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_landscape"></a> [landscape](#requirement\_landscape) | ~> 0.1.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_landscape"></a> [landscape](#provider\_landscape) | 0.1.10 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| landscape_distribution.ubuntu | resource |
| landscape_gpg_key.mirror | resource |
| landscape_repository_profile.mirror | resource |
| landscape_script_profile.welcome | resource |
| landscape_script_v2.welcome | resource |
| landscape_series.ubuntu | resource |
| [terraform_data.setup_postfix](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.wait_for_landscape](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_email"></a> [admin\_email](#input\_admin\_email) | Landscape admin email. | `string` | n/a | yes |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Landscape admin password. | `string` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain used for Landscape Server. | `string` | n/a | yes |
| <a name="input_server_ip"></a> [server\_ip](#input\_server\_ip) | Landscape Server IP address. | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Juju model name. | `string` | n/a | yes |
| <a name="input_gpg_key"></a> [gpg\_key](#input\_gpg\_key) | ASCII-armored GPG private key for repository mirroring (optional). | `string` | `null` | no |
| <a name="input_mirror_series"></a> [mirror\_series](#input\_mirror\_series) | Ubuntu series to mirror (e.g. noble, jammy). | `string` | `"noble"` | no |
| <a name="input_smtp_host"></a> [smtp\_host](#input\_smtp\_host) | SMTP relay hostname. Set to null to skip Postfix configuration. | `string` | `null` | no |
| <a name="input_smtp_password"></a> [smtp\_password](#input\_smtp\_password) | SMTP relay password. | `string` | `""` | no |
| <a name="input_smtp_port"></a> [smtp\_port](#input\_smtp\_port) | SMTP relay port. | `number` | `587` | no |
| <a name="input_smtp_username"></a> [smtp\_username](#input\_smtp\_username) | SMTP relay username. | `string` | `""` | no |
| <a name="input_tls_ca_cert"></a> [tls\_ca\_cert](#input\_tls\_ca\_cert) | PEM-encoded CA certificate for Landscape Server TLS. | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->