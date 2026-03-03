# Landscape Demo

Spin up a preconfigured, local Landscape demo using Terraform and Juju.

## Prerequisites

Install [Juju](https://github.com/juju/juju), [LXD](https://github.com/canonical/lxd), and [yq](https://github.com/mikefarah/yq):

```bash
sudo snap install juju --classic
sudo snap install lxd
sudo snap install yq
```

Install Terraform:

```bash
sudo snap install terraform --classic
```

> [!IMPORTANT]
> Ensure you're in the `lxd` group, then initialize LXD:
>
> ```sh
> sudo usermod -aG lxd "$USER" && newgrp lxd
> lxd init --minimal
> ```

If you want Ubuntu Core devices (optional), install [Multipass](https://github.com/canonical/multipass):

```sh
sudo snap install multipass
```

Bootstrap a Juju controller on LXD (only needed once per machine):

```bash
juju bootstrap lxd landscape-controller
```

## Configuration

### 1. Copy and edit `terraform.tfvars`

```sh
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values. All variables and their types are documented in [`variables.tf`](./variables.tf).

Minimum required values:

| Variable          | Description                                                      |
| ----------------- | ---------------------------------------------------------------- |
| `workspace_name`  | Name of the Juju model and Terraform workspace                   |
| `path_to_ssh_key` | Path to your SSH public key                                      |
| `pro_token`       | Ubuntu Pro token ([dashboard](https://ubuntu.com/pro/dashboard)) |
| `admin_email`     | Landscape admin email                                            |
| `admin_password`  | Landscape admin password                                         |

### 2. HAProxy: internal vs. external

- **Landscape 26.04 LTS beta+** ships with an internal HAProxy — set `haproxy = null` (the default).
- **Pre-26.04** deployments require the external HAProxy charm — set `haproxy = {}` or provide a full config block.

### 3. (Optional) SMTP relay

Uncomment and fill in the `smtp_*` variables in `terraform.tfvars` to configure Postfix on the Landscape Server unit for outgoing email.

## Deploying

### Phase 1 — deploy Landscape Server and wait

Initialize and create the workspace:

```bash
terraform init
terraform workspace new <workspace_name>
terraform workspace select <workspace_name>
```

Apply targeting only the server (clients need `/etc/hosts` set first):

```bash
terraform apply -target module.landscape_server
```

### Phase 2 — update `/etc/hosts`

Once the server is up, retrieve its IP and add it to `/etc/hosts` on **every machine that needs to reach the Landscape UI** (including the machine running Terraform):

Landscape 26.04 LTS beta+ (internal HAProxy):

```sh
juju show-unit -m <workspace_name> landscape-server/0 | yq '."landscape-server/0"."public-address"'
```

Pre-26.04 (external HAProxy charm):

```sh
juju show-unit -m <workspace_name> haproxy/0 | yq '."haproxy/0"."public-address"'
```

Then add the entry:

```sh
echo "<IP>  <hostname>.<domain>" | sudo tee -a /etc/hosts
```

### Phase 3 — apply everything

```bash
terraform apply
```

Terraform outputs the Landscape URL and the IP retrieval commands after each apply.

## Updating

Update values in `terraform.tfvars`, then:

```bash
terraform workspace select <workspace_name>
terraform apply
```

## Accessing the Juju model

```sh
juju status -m <workspace_name> --relations
juju ssh -m <workspace_name> landscape-server/leader
```

> [!CAUTION]
> Use `juju ssh` for read-only access only. Modifying the model with other Juju CLI commands can break Terraform state.

## Tearing down

```bash
terraform workspace select <workspace_name>
terraform destroy
terraform workspace select default
terraform workspace delete <workspace_name>
juju destroy-model --no-prompt <workspace_name> --no-wait --force --destroy-storage
```

Remove the `/etc/hosts` entry you added manually:

```sh
sudo sed -i '/<hostname>\.<domain>/d' /etc/hosts
```

## Destroying the LXD controller

Only needed if you want to remove the controller entirely:

```bash
juju destroy-controller --no-prompt landscape-controller --destroy-all-models --no-wait --force
```

## Reference

<--- <exception caught here> BEGIN_TF_DOCS -->
<--- <exception caught here> END_TF_DOCS -->
