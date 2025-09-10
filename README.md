# Landscape Demo

Spin up a preconfigured, local Landscape demo. Your system's `/etc/hosts` file will get modified so that you can access Landscape at the specified address. By default, this will be `landscape.example.com`.

## Installing and configuring prerequisites

You need to have [snapd](https://snapcraft.io/docs/installing-snapd) installed and configured.

Clone this repository, change into the directory, and make the scripts executable:

```bash
git clone git@github.com:jansdhillon/landscape-demo.git
cd landscape-demo
# Make the scripts executable
find . -type f -name "*.sh" -exec chmod +x {} +
```

Install the [Juju](https://github.com/juju/juju), [LXD](https://github.com/canonical/lxd), [Multipass](https://github.com/canonical/multipass), [OpenTofu](https://github.com/opentofu/opentofu), and [yq](https://github.com/mikefarah/yq) snaps:

```bash
sudo snap install juju --classic
sudo snap install lxd
sudo snap install multipass
sudo snap install opentofu --classic
sudo snap install yq
```

> [!IMPORTANT]
> Make sure you're in the `lxd` group:
>
> ````sh
> if ! getent group lxd | grep "$USER"; then
>   sudo usermod -aG lxd "$USER"
>   newgrp lxd
> fi
> ````
>
> If you've never initialized LXD, do so now:
>
> ````sh
> lxd init --minimal
> ````
>

Then, create a local LXD cloud with Juju, which will allow us to easily orchestrate the lifecycle of our Landscape system:

```bash
juju bootstrap lxd landscape-controller
```

> [!IMPORTANT]
> There can be multiple workspaces using this cloud, so you only need to do this once.

## Setting up the workspace

### Ubuntu Pro

You need an Ubuntu Pro token to use Landscape, which you can get from the [Ubuntu Pro dashboard](https://ubuntu.com/pro/dashboard). Put the token value in [`terraform.tfvars.example`](./terraform.tfvars.example#L5) for `pro_token`.

### SSH public key

You need to set the path to the SSH public key you want to use for the workspace as the value for for `path_to_ssh_key` in [`terraform.tfvars.example`](./terraform.tfvars.example#L8).

### (**Optional**) Creating a GPG private key for repository mirroring

This demo can also setup [repository mirroring](https://documentation.ubuntu.com/landscape/explanation/repository-mirroring/repository-mirroring/) for Landscape. To do so, create a GPG private key to sign the packages and metadata. **The key you use must not have a passphrase**, so do not enter anything for a password when prompted:

````sh
gpg --full-generate-key
````

After following the prompts in the terminal, the key will be created and the ID of the key will be printed beside `pub` and under the type of key and today's date.

Use that value to export the key, replacing `"<KEY-ID>"`:

```sh
gpg --armor --export-secret-keys "<KEY-ID>" > private.asc
```

Then, put the full or relative path of the GPG private key as the value for `path_to_gpg_private_key` in [`terraform.tfvars.example`](./terraform.tfvars.example#L17).

> [!NOTE]
> You can also set other configuration options in [`terraform.tfvars.example`](./terraform.tfvars.example), such as the details of the Landscape Server deployment and the Landscape Client instances. The corresponding types and descriptions can also be found in [`variables.tf`](./variables.tf).

### (**Optional**) Using a custom domain

To use your own domain for the root URL, you must have the access to the SSL certificate and private key on your local filesystem. You can use `certbot` to do this:

```sh
sudo snap install certbot --classic
```

```sh
sudo certbot certonly --manual --preferred-challenges dns -d "<your-domain.com>"
```

> [!NOTE]
> If your custom domain already has a wildcard record (i.e., `*.your-domain.com`), you should use `<hostname.your-domain.com>` instead, where `hostname` matches the entry in [`terraform.tfvars.example`](./terraform.tfvars.example#L19).

Put paths of the certificate and private key in [`terraform.tfvars.example`](./terraform.tfvars.example) for `path_to_ssl_cert` and `path_to_ssl_key`, respectively. You should use the paths of the `fullchain.pem` and `privkey.pem` files.

> [!TIP]
> You can see where `certbot` saved the certificates using:
>
> ````sh
> sudo certbot certificates -d "<your-domain.com>"
> ````

#### SMTP (Postfix/System Email)

> [!NOTE]
> A custom domain can be used **without** configuring SMTP.

To perform actions like inviting new administrators to Landscape, we need to configure Postfix and SMTP relay for Landscape. You can use [SendGrid](https://sendgrid.com/), but there are several email service providers that can be configured to work with Postfix.

If using SMTP, populate the following values in [`terraform.tfvars.example`](./terraform.tfvars.example#L17):

- smtp_host
- smtp_port
- smtp_username
- smtp_password

### Renaming `terraform.tfvars.example` to `terraform.tfvars`

Finally, remove the `.example` extension from [`terraform.tfvars.example`](./terraform.tfvars.example). The file should now be named **`terraform.tfvars`**.

> [!WARNING]
> You must have followed the steps to add [your Ubuntu Pro token](#ubuntu-pro) to `terraform.tfvars` before proceeding.

## Running the demo using the workspace

Finally, you can create the workspace for the infrastructure and start Landscape with [`run.sh`](./run.sh)

```bash
./run.sh
```

> [!TIP]
> Press `CTRL+C` while the script is running to cleanup and destroy
> the infrastucture.

You can specify the workspace name to create or use. For example:

```sh
./run.sh landscape
```

> [!WARNING]
> If using Ubuntu Core, it's possible that Multipass will time out while provisioning Ubuntu Core devices to register with Landscape. The devices should still register eventually, but the timeout is unfortunately not configurable.

### Script execution

A script was added to Landscape Server, along with a script profile which makes it execute on the Landscape Client instances upon registering.

After Landscape has finished deploying, in the Activities tab, you can see that it ran on the Landscape Client instance(s). After the script has finished running, you can also verify it using the following:

```bash
lxc exec client-0 -- bash -c "sudo cat /root/landscape.txt"
# Welcome to Landscape!
```

> [!NOTE]
> Replace "client-0" with the value you set for `computer_title` for any LXD instance in the `lxd_vms` config of `terraform.tfvars`.

### Repository mirroring

> [!NOTE]
> This section is only applicable if you created a GPG key and set the path as `path_to_gpg_private_key` before running the workspace.

If you added a GPG key when deploying the workspace, [repository mirroring](https://documentation.ubuntu.com/landscape/explanation/repository-mirroring/repository-mirroring/) was automatically configured in Landscape to sync the packages of registered Landscape Client instances with specific pockets of a given Ubuntu series. To accomplish this, a repository profile was created to "apply" the mirror to the LXD VM(s).

Using the **new web portal** (`/new_dashboard`), you can see the repository profile by going to **Profiles > Repository profiles**, and the repository mirror by going to **Repositories > Mirrors**.

Additionally, you should see the `Apply repository profiles` activity under the **Activities** tab to apply the mirror to the Landscape Client instances.

## Updating the workspace

To update the Landscape deployment, simply update the values in `terraform.tfvars`. Then you can use [`update.sh`](./update.sh):

```bash
./update.sh
```

You can specify a workspace to update with the first argument.
For example:

````sh
./update.sh landscape
````

This should be used with caution, as it will cause the affected resources to be **replaced entirely** and can have unintended side effects due to the dependencies betwen them. It's safest when used to update the variables related to the Landscape Client instances (Ubuntu Core devices and LXD VMs).

### Accessing the Landscape Server Juju model

For convenience, the underlying Juju model that manages Landscape Server uses the same name as the workspace. You can see the status with:

```sh
juju status -m landscape --relations # replace with 'workspace_name'
```

You can then use this information to access specific instances running within the Juju model with `juju ssh -m`. For example, to connect to the main Landscape Server machine, you can use:

```sh
juju ssh -m landscape landscape-server/leader
```

> [!CAUTION]
> While connecting to the instances with `juju ssh` is safe, modifying the Juju model with other Juju CLI commands is not and can cause issues with the Terraform plans.

## Tearing down the workspace

You can easily clean up the workspace using [`destroy.sh`](./destroy.sh):

```bash
./destroy.sh
```

You can specify a workspace to destroy with the first argument.
For example:

```sh
./destroy.sh landscape
```

## Destroying the LXD cloud

While you don't need to destroy the LXD cloud in order to create a new workspace (i.e., run a new demo), you can do so with the following:

```bash
juju destroy-controller --no-prompt landscape-controller --destroy-all-models --no-wait --force
```
