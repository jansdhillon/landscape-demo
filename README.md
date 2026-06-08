# Landscape Demo Deployment

Terraform deployment of Landscape Server with demo client machines, built to the CC008 spec. Everything runs via Juju charms — no Terragrunt, no LXD provider, no external scripts.

Two Juju models are created: one for the Landscape server stack, one for the demo client machines. The client model's `cloudinit-userdata` is set at apply time (after the server is up) so client machines boot with the correct `/etc/hosts` entry and can reach the server by FQDN.

## Prerequisites

- Juju controller bootstrapped and logged in
- [OpenTofu](https://opentofu.org/) ≥ 1.0
- `jq` (used to read the server IP from `juju status` during apply)

## Quick start

```sh
cp terraform.tfvars.example terraform.tfvars
# fill in admin_email, admin_password, landscape_fqdn, etc.

tofu init
tofu apply
```

The apply will wait for Landscape Server to become active before provisioning client machines.

## Key variables

| Variable | Default | Notes |
|---|---|---|
| `model_name` | `landscape-demo` | Server model |
| `client_model_name` | `landscape-demo-clients` | Client machines model |
| `landscape_fqdn` | `landscape.local` | Must resolve from client machines — injected into `/etc/hosts` automatically |
| `admin_email` | — | Required |
| `admin_password` | — | Required |
| `registration_key` | `""` | Auto-registration key |
| `landscape_client.units` | `3` | Number of demo client machines |
| `landscape_server.channel` | `26.04/edge` | |
| `landscape_server.revision` | `355` | |

## Layout

```
main.tf                    # models, server stack, client machines, CMR wiring
variables.tf               # all inputs
outputs.tf                 # landscape_url, model_name, client_model_name
modules/landscape-client/  # landscape-client charm module
```
