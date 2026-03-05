# Landscape Demo

Spin up a preconfigured, local Landscape demo using Terragrunt and Juju.

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

Install Terragrunt:

```bash
curl -sL https://docs.terragrunt.com/install | bash
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

### 1. Copy and edit `root.hcl`

```sh
cp root.hcl.example root.hcl
```

Edit `root.hcl` with your values. All configuration lives in the `locals` block at the top of this file.

Minimum required values:

| Local             | Description                                                      |
| ----------------- | ---------------------------------------------------------------- |
| `workspace_name`  | Name of the Juju model                                           |
| `path_to_ssh_key` | Path to your SSH public key                                      |
| `pro_token`       | Ubuntu Pro token ([dashboard](https://ubuntu.com/pro/dashboard)) |
| `admin_email`     | Landscape admin email                                            |
| `admin_password`  | Landscape admin password                                         |

### 2. HAProxy: internal vs. external

- **Landscape 26.04 LTS beta+** ships with an internal HAProxy — set `haproxy = null` (the default).
- **Pre-26.04** deployments require the external HAProxy charm — set `haproxy = {}`.

### 3. (Optional) SMTP relay

Set `smtp_host`, `smtp_username`, and `smtp_password` in `root.hcl` to configure Postfix on the Landscape Server unit for outgoing email.

### 4. (Optional) Repository mirroring

Export your GPG signing key and set `gpg_key_file` to its path:

```bash
gpg --export-secret-keys --armor <KEY_ID> > mirror-key.asc
```

Then in `root.hcl`:

```hcl
gpg_key_file  = "mirror-key.asc"
mirror_series = "noble"
```

## Deploying

Initialize all modules:

```bash
terragrunt run --all init
```

Deploy in one shot (Terragrunt resolves dependency order automatically):

```bash
terragrunt run --all apply
```

Or step by step:

```bash
cd deploy && terragrunt apply

cd .. && terragrunt run --all apply --terragrunt-exclude-dir deploy
```

## Updating

Edit `root.hcl`, then:

```bash
terragrunt run --all apply
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
terragrunt run --all destroy
juju destroy-model --no-prompt <workspace_name> --no-wait --force --destroy-storage
```

## Destroying the LXD controller

Only needed if you want to remove the controller entirely:

```bash
juju destroy-controller --no-prompt landscape-controller --destroy-all-models --no-wait --force
```
