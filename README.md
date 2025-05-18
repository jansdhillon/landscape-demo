# Landscape Demo

Spin up a preconfigured Landscape and Livepatch demo with containers and virtual machines with outstanding ESM security patching tasks. The demo will run on landscape.example.com, and your system's `/etc/hosts` file will get modified so that you can access the demo at that address.

## Step 1. Install and configure Landscape Server with Juju

You need the Juju, LXD, and yq snap packages to be installed on your Linux machine to run a local Landscape demo.

Clone this repository and make scripts executable:

> ```bash
> git clone git@github.com:rajannpatel/ubuntu-instances.git
> cd ubuntu-instances
> chmod +x *.sh
> ```

Install and configure the packages the scripts in this repository expect to find on your machine.

> ```bash
> sudo snap install yq
> sudo snap install lxd
> sudo snap install juju --classic
> ```

Initialize LXD

> ```bash
> lxd init --auto
> ```

For the LXD container to reach the external network, the MTU on the bridge must match the default network adapter. This extra step is necessary in some virtualized environments, such as Google Cloud's Compute Engine where the MTU is lower, or Oracle Cloud where jumbo frames are enabled by default, and the MTU is higher. This is not likely to impact you on most networks, where the default MTU is 1500.

> ```bash
> read -r INTERFACE < <(ip route | awk '$1=="default"{print $5; exit}')
> lxc network set lxdbr0 bridge.mtu=$(ip link show $INTERFACE | awk '/mtu/ {print $5}')
> ```

Create a LXD controller for our Juju model

```bash
juju bootstrap lxd
```

Now, let's create a model for our Juju deployment of Landscape:

```bash
juju add-model landscape
```

## Step 2. Create the Ubuntu instances

[./add.sh](add.sh) will create Ubuntu instances, starting with Landscape Server, followed by Landscape Client instances.

All new instances will be named with a common prefix, to keep things organized. The prefix is in `DAYHHMM` format

Landscape Server will be launched in an Ubuntu 24.04.2 LTS ("Noble Numbat") LXD container.

The [./add.sh](add.sh) script is going to launch AMD64 Ubuntu instances as follows:

```bash
lxd_virtualmachines=("focal")
lxd_containers=("jammy" "noble")
```

Older fingerprints of each image will be used, when available, for demoing security patching with Livepatch and Landscape.

You will be prompted for the sudo password, when the script attempts to write to `/etc/hosts` or read SSL certificates from protected locations. cloud-init may sometimes print `status: error` in the output when running add.sh with certain SSL configurations, this can be safely ignored.

Example output:

```text
./add.sh 
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                              Dload  Upload   Total   Spent    Left  Speed
100  3832  100  3832    0     0  23221      0 --:--:-- --:--:-- --:--:-- 23365
[sudo] password for rajan: 
Creating wed0022-landscape-example-com
Starting wed0022-landscape-example-com    
...
status: done
Device tcp6554proxyv4 added to wed0022-landscape-example-com
Device tcp443proxyv4 added to wed0022-landscape-example-com
Device tcp80proxyv4 added to wed0022-landscape-example-com
Visit https://landscape.example.com to finalize Landscape Server configuration,
then press Enter to continue provisioning Ubuntu instances, or CTRL+C to exit...
```

## Starting, Stopping, and Deleting the Ubuntu instances

-  [./start.sh](start.sh) and [./stop.sh](stop.sh) can start and stop every Ubuntu instance with your chosen `DAYHHMM` prefix, 
-  [./remove.sh](stop.sh) can delete sets of LXD containers and virtual machines. If more than one instance is detected with a `DAYHHMM` prefix, it will be added to a list. Choose which grouping of containers and virtual machines you wish to delete.

---

## TODO:

- Run `pro fix` commands on each Landscape-managed Ubuntu instance after provisioning. This simulates patch drift between various machines, and makes for more interesting demos.
- snapshot.sh will take a point in time snapshot of Landscape and a selection of LXD instances.
- restore.sh will restore a point in time snapshot of Landscape and a selection of LXD instances.
- REST API enhancements to preconfigure scripts, repository mirrors, and profiles, to make the demo more complete.
- Use Juju instead of quickstart
