# Landscape Demo Deployment

A CC008-compliant Terraform deployment of Landscape Server with demo client machines,
deployed entirely via Juju charms — no Terragrunt, no LXD provider, no multipass.

## Prerequisites

- Juju controller bootstrapped on LXD:
  ```sh
  juju bootstrap lxd landscape-controller
  ```
- [OpenTofu](https://opentofu.org/) ≥ 1.0:
  ```sh
  sudo snap install --classic opentofu
  ```
- [yq](https://github.com/mikefarah/yq) for status queries:
  ```sh
  sudo snap install yq
  ```

## Quick start

1. Copy and edit `terraform.tfvars`:

   ```sh
   cp terraform.tfvars.example terraform.tfvars
   # edit terraform.tfvars with your values
   ```

2. Initialize and apply:

   ```sh
   tofu init
   tofu apply
   ```

3. After apply, find the server IP and add a `/etc/hosts` entry:

   ```sh
   juju status -m landscape-demo
   # Add to /etc/hosts: <server-ip>  landscape.local
   ```

## Key variables

| Variable                   | Description                                           | Default           |
|----------------------------|-------------------------------------------------------|-------------------|
| `model_name`               | Juju model name                                       | `landscape-demo`  |
| `admin_email`              | Landscape admin email (required)                      |                   |
| `admin_password`           | Landscape admin password (required)                   |                   |
| `landscape_fqdn`           | FQDN used in server config and client URL             | `landscape.local` |
| `registration_key`         | Auto-registration key                                 | `""`              |
| `landscape_client.units`   | Number of demo client machines                        | `3`               |
| `landscape_server.channel` | Landscape Server charm channel                        | `26.04/edge`      |
| `landscape_server.revision`| Landscape Server charm revision                       | `355`             |

## Demo data

Demo data (accounts, machines, policies) is seeded automatically via the
`add-demo-data` charm action on landscape-server rev355, `26.04/edge`.

## Architecture

```
landscape-demo/
├── main.tf                    # Model, landscape-server, landscape-client, demo data
├── variables.tf               # All deployment inputs
├── outputs.tf                 # landscape_url, model_name
├── locals.tf                  # model local
├── terraform.tf               # Provider requirements
├── providers.tf               # Juju provider
├── backend.tf                 # Local state backend
└── modules/
    └── landscape-client/      # CC008 charm module for landscape-client charm
```

## Modules

- `modules/landscape-client/` — CC008 charm module for the `landscape-client` charm.
  Deploys the landscape-client Juju charm on machines and handles registration
  retries automatically via Juju's event system.
