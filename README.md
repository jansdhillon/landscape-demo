# Landscape Demo

Spin up a preconfigured, local Landscape demo. The demo will use `landscape.example.com`, and your system's `/etc/hosts` file will get modified so that you can access the demo at that address.

## Install and configure Landscape Server with Juju and OpenTofu


Clone this repository and change into the directory:

```bash
git clone git@github.com:jansdhillon/landscape-demo.git
cd landscape-demo
```

In this demo we will use the Juju, LXD, Multipass, OpenTofu, and yq snaps. Install
them if you have not already:

```bash
sudo snap install yq
sudo snap install lxd
sudo snap install juju --classic
sudo snap install multipass
sudo snap install opentofu --classic
```

LXD has additional initialization steps that must be followed before proceeding. See [the LXD documentation](https://documentation.ubuntu.com/lxd) to get set up.


Then, create a local LXD cloud with Juju, which will allow us to easily orchestrate the lifecycle of our Landscape system:

```bash
juju bootstrap lxd landscape-controller
```

## Setting up

Fill in the values in [terraform.tfvars.example](./terraform.tfvars.example) and rename the file to remove the `.example` extension.

You need an Ubuntu Pro token to use Landscape, which you can get for free [here](https://ubuntu.com/pro/dashboard). Put the token value in [terraform.tfvars](./terraform.tfvars) for `pro_token`.


To run Landscape, starting with Landscape Server and other applications it depends on, followed by some Landscape Client instances that are managed by Landscape Server, we can use [OpenTofu](https://opentofu.org) and the [Juju Provider for Terraform](https://registry.terraform.io/providers/juju/juju/latest/docs).

First, let's create a new workspace and initialize our working directory with OpenTofu:

```bash
tofu init
tofu workspace new landscape
```

Then, preview the infrastructure to be deployed:

```bash
tofu plan
```

And finally, create it:

```bash
tofu apply -auto-approve
```

This may take some time. You can use `juju status -m landscape --watch 2s --relations --storage` to watch the lifecycle of the applications unfold.

## Script Execution

[./example.sh](example.sh) was added to Landscape Server, along with a script profile which makes it execute on the Landscape Client instances upon being registered.

Additionally, in the [Activities tab](https://landscape.example.com/new_dashboard/activities), you can see that it ran on the Landscape Client instances.

After the script has finished running, we can also verify this using the following:

```bash
lxc exec vulnerable -- bash -c "sudo cat /root/hello.txt"
# Hello world!
```

## Tearing Down and Cleaning Up

We can easily clean up our resources with OpenTofu:

```bash
tofu destroy -auto-approve
# switch back to default worksapce
tofu workspace select default
tofu workspace delete landscape
# double check that the Juju model was deleted
# replace 'landscape' with another model name if needed
juju destroy-model --no-prompt landscape --no-wait --force
```
