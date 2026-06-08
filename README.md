# Landscape Demo Deployment

A charmed, Terraform-based deployment of Landscape, including demo data and client machines.

Two Juju models are created: one for the Landscape server stack, one for the demo client machines. The client model's `cloudinit-userdata` is set at apply time (after the server is up and its IP is known) so client machines boot with the correct `/etc/hosts` entry. The landscape-client charm is then deployed as a subordinate on the ubuntu machines and registers with the server via charm config.

## Prerequisites

- Juju controller bootstrapped and logged in
- Terraform or OpenTofu installed
- jq installed (used to read the server IP from `juju status` during apply)

## Quick start

```sh
cp terraform.tfvars.example terraform.tfvars
# fill in ubuntu_pro_token, admin_email, admin_password, landscape_root_url, etc.

terraform init
terraform apply
```
