# Landscape Demo

Spin up a preconfigured, local Landscape demo. Your system's `/etc/hosts` file will get modified so that you can access the demo at the address specified.

## Install and configure Landscape Server with Juju and OpenTofu

Clone this repository, change into the directory, and make the scripts executable:

```bash
git clone git@github.com:jansdhillon/landscape-demo.git
cd landscape-demo
chmod +x *.sh
```

In this demo we will use the Juju, LXD, Multipass, OpenTofu, and yq snaps. Install them if you have not already:

```bash
sudo snap install yq
sudo snap install lxd
sudo snap install juju --classic
sudo snap install multipass
sudo snap install opentofu --classic
```

> [!IMPORTANT]
> LXD has additional initialization steps that must be followed before proceeding. See [the LXD documentation](https://documentation.ubuntu.com/lxd) to get set up.


Then, create a local LXD cloud with Juju, which will allow us to easily orchestrate the lifecycle of our Landscape system:

```bash
juju bootstrap lxd landscape-controller
```

## Setting up

Fill in the values in [terraform.tfvars.json.example](./terraform.tfvars.json.example) and rename the file to remove the `.example` extension.

You need an Ubuntu Pro token to use Landscape, which you can get for free [here](https://ubuntu.com/pro/dashboard). Put the token value in [terraform.tfvars.json](./terraform.tfvars.json) for `pro_token`. 

You can also set other configuration options in that file; their corresponding types and descriptions are in [variables.tf](./variables.tf).

Finally, we can create the workspace for our infrastructure and run Landscape with [run.sh](./run.sh)

```bash
./run.sh
```

> [!TIP]
> You specify the workspace name to create or use. For example:
> ```
> ./run.sh landscape
> ```

> [!TIP]
> Press `CTRL+C` while the script is running to cleanup and destroy
> the infrastucture.

## Script Execution

[welcome.sh](./welcome.sh) was added to Landscape Server, along with a script profile which makes it execute on the Landscape Client instances upon being registered.

Additionally, in the [Activities tab](https://landscape.example.com/new_dashboard/activities), you can see that it ran on the Landscape Client instances.

After the script has finished running, we can also verify this using the following:

```bash
lxc exec landscape-vulnerable-0 -- bash -c "sudo cat /root/hello.txt"
# Hello world!
```

> [!NOTE]
> The above command will need to be adjusted based on the name
> of the workspace and the LXD VM name
> using the following format: `{workspace_name}-{lxd_vm_name}-{index}`


## Tearing Down and Cleaning Up

We can easily clean up our workspace using [destroy.sh](./destroy.sh):

```bash
./destroy.sh
```

> [!TIP]
> You can pecificy a workspace to destroy with the first argument. 
> For example:
> ```
> ./destroy.sh landscape
> ```
