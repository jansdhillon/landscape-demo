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

After the apply succeeds, get the IP addres of the HAProxy unit in the main model:

```sh
# replace `landscape-demo` with the name of the model Landscape Server
# is running in, and `landscape.local` with the configured hostname, if changed.
IP=$(juju status --model landscape-demo --format=json | jq -r '.applications["haproxy"].units | to_entries[0].value["public-address"]')
echo "$IP landscape.local" | sudo tee -a /etc/hosts
```

Then, you can access the Landscape UI in your web browser at https://landscape.local (or whatever you set the root URL to).
