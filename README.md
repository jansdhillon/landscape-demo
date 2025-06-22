# Landscape Demo

Spin up a preconfigured, local Landscape demo. Your system's `/etc/hosts` file will get modified so that you can access Landscape at the address you specify.

## Installing and configuring prerequisites

> [!WARNING]
> The following has only been tested on x86_64 architecture.

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
> LXD has additional initialization steps that must be followed before proceeding. See [the LXD documentation](https://documentation.ubuntu.com/lxd) to get set up.


Then, create a local LXD cloud with Juju, which will allow us to easily orchestrate the lifecycle of our Landscape system:

```bash
juju bootstrap lxd landscape-controller
```

> [!IMPORTANT]
> There can be multiple workspaces using this cloud, so you only need to do this once.


## Setting up the workspace

You need an Ubuntu Pro token to use Landscape, which you can get for free [here](https://ubuntu.com/pro/dashboard). Put the token value in [terraform.tfvars.example](./terraform.tfvars.example) for `pro_token`. 

> [!NOTE]
> You can also set other configuration options in that file, such as the details of the Landscape Server deployment and the Landscape Client instances. The corresponding types and descriptions can also be found in [variables.tf](./variables.tf).

Then, remove the `.example` extension from `terraform.tfvars.example`. You should now only have `terraform.tfvars`.

> [!WARNING]
> You must rename `terraform.tfvars.example` and add your Ubuntu Pro token before proceeding.

## Running the demo

Finally, you can create the workspace for the infrastructure and start Landscape with [run.sh](./run.sh)

```bash
./run.sh
```

> [!NOTE]
> You can specify the workspace name to create or use. For example:
> ```
> ./run.sh landscape
> ```

> [!TIP]
> Press `CTRL+C` while the script is running to cleanup and destroy
> the infrastucture.

> [!WARNING]
> It's possible that Multipass will time out while provisioning Ubuntu Core devices to register with
> Landscape. They should still register eventually, but the timeout is unfortunately not configurable.
> However, [destroy.sh](./destroy.sh) does take this into account.

## Trigger-based script execution

A script was added to Landscape Server, along with a script profile which makes it execute on the Landscape Client instances upon registering.

In the Activities tab, you can see that it ran on the Landscape Client instance(s). After the script has finished running, you can also verify it using the following:

```bash
lxc exec landscape-client-0 -- bash -c "sudo cat /root/hello.txt"
# Hello world!
```

> [!NOTE]
> The above command will need to be adjusted based on the name
> of the workspace and the LXD VM name
> using the following format: `{workspace_name}-{lxd_vm_name}-0`


## Tearing down the workspace

You can easily clean up the workspace using [destroy.sh](./destroy.sh):

```bash
./destroy.sh
```

> [!NOTE]
> You can specify a workspace to destroy with the first argument. 
> For example:
> ```
> ./destroy.sh landscape
> ```

## Destroying the LXD cloud

While you don't need to destroy the LXD cloud in order to create a new workspace (i.e., run a new demo), you can do so with the following:

```bash
juju destroy-controller --no-prompt landscape-controller --destroy-all-models --no-wait --force
```
