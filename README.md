Kubernetes Solo cluster for macOS
============================

![k8s-solo](k8s-singlenode.png)

Zero to Kubernetes development environment
---------------

**Kube-Solo for macOS** is `status bar App` which allows in an easy way to control and bootstrap Kubernetes cluster on a standalone [CoreOS](https://coreos.com) VM machine.

It leverages macOS native Hypervisor framework of using [xhyve](https://github.com/xhyve-xyz/xhyve) based [corectl](https://github.com/TheNewNormal/corectl) command line tool without any needs to use VirtualBox or similar virtualisation software.

Also there is [Kube-Cluster for macOS](https://github.com/TheNewNormal/kube-cluster-osx) App (master + 2 nodes) if you are interested to run a multi-node Kubernetes cluster on your Mac.

**Includes:** [Helm Classic](https://helm.sh) - The Kubernetes Package Manager

**Includes:** An option from shell to install [Deis Workflow](https://deis.com) on top of Kubernetes with a simple: `$ install_deis`

Kube-Solo App can be used together with [CoreOS VM App](https://github.com/TheNewNormal/coreos-osx) which allows to build Docker containers and has a private local Docker registry v2 which is accessible from Kube-Solo App.


![Kube-Solo](kube-solo-osx.png "Kubernetes-Solo")

Download
--------
Head over to the [Releases Page](https://github.com/TheNewNormal/kube-solo-osx/releases) to grab the latest release.


How to install Kube-Solo
----------

**Requirements**
 -----------
  - **macOS 10.10.3** Yosemite or later 
  - Mac 2010 or later for this to work.
  - [Corectl App](https://github.com/TheNewNormal/corectl.app) is installed, which will serve as `corectld` server daemon control.
  - **Note:** For the fresh App install it is recommended to restart your Mac if you have used VirtualBox based VM, as the VirtualBox sometimes messes networking up.


###Install:

Open downloaded `dmg` file and drag the App e.g. to your Desktop. Start the `Kube-Solo` App and `Initial setup of Kube-Solo VM` will run.


* All dependent files/folders will be put under `kube-solo` folder in the user's home folder e.g /Users/someuser/kube-solo. 
* user-data file will have fleet and etcd enabled
* Will download latest CoreOS ISO image and run `corectl` to initialise VM 
* When you first time do install or 'Up' after destroying Kube-Solo setup, k8s binary files (with the version which was available when the App was built) get copied to CoreOS VM, this speeds up Kubernetes setup. To update Kubernetes just run from menu 'Updates' - Update Kubernetes to latest stable version.
* It will install `fleetctl and kubectl` to `~/kube-solo/bin/`
* Kubernetes services will be installed with fleet units which are placed in `~/kube-solo/fleet`, this allows very easy updates to fleet units if needed.
* [Fleet-UI](http://fleetui.com) via unit file will be installed to check running fleet units
* [Kubernetes Dashboard](http://kubernetes.io/docs/user-guide/ui/), [DNS](https://github.com/kubernetes/kubernetes/blob/release-1.2/cluster/addons/dns/README.md) and [Kubedash](https://github.com/kubernetes/kubedash) will be instlled as add-ons
* Via assigned static IP (it will be shown in first boot and will survive VM's reboots) you can access any port on CoreOS VM
* Persistent disk `data.img` will be created and mounted to `/data` for these mount binds:

```
/data/var/lib/docker -> /var/lib/docker
/data/var/lib/rkt -> /var/lib/rkt
/data/var/lib/etcd2 -> /var/lib/etcd2
/data/opt/bin -> /opt/bin
```

How it works
------------

Just start `Kube-Solo` application and you will find a small icon of Kubernetes logo with `S` in the Status Bar.

* There you can `Up` and `Halt` CoreOS VM + Kubernetes Cluster
* `SSH to k8solo-01` will open VM shell
* Under `Up` OS Shell will be opened when VM boot finishes up and it will have such environment pre-set:

````
1) kubernetes master - export KUBERNETES_MASTER=http://192.168.64.xxx:8080
2) etcd endpoint - export ETCDCTL_PEERS=http://192.168.64.xxx:2379
3) fleetctl endpoint - export FLEETCTL_ENDPOINT=http://192.168.64.xxx:2379
4) fleetctl driver - export FLEETCTL_DRIVER=etcd
5) Path to ~/kube-solo/bin where fleetctl and kubectl are stored
````

* [Fleet-UI](http://fleetui.com) dashboard will show running fleet units and etc
* [Kubernetes Dashboard](http://kubernetes.io/docs/user-guide/ui/) will show nice Kubernetes Dashboard, where you can check Nodes, Pods, Replication, Deployments, Service Controllers, deploy Apps and etc.
* [Kubedash](https://github.com/kubernetes/kubedash) is a performance analytics UI for Kubernetes Clusters
* `Updates/Update Kubernetes to the latest version` will update to latest version of Kubernetes.
* `Updates/Change Kubernetes version` will download and install specified Kubernetes version from GitHub.
* `Updates/Update macOS fleetctl, helmc and deis clients` will update fleetctl to the same versions as CoreOS VM runs and update `helmc` and `deis` to the latest version.

Example ouput of succesfull CoreOS + Kubernetes Solo install:

````
etcd cluster:192.168.64.2
/coreos.com
/registry

fleetctl list-machines:
MACHINE		IP		METADATA
c576b883...	192.168.64.2	role=kube

fleetctl list-units:
UNIT									MACHINE				ACTIVE	SUB
fleet-ui.service				c576b883.../192.168.64.2	active	running
kube-apiserver.service			c576b883.../192.168.64.2	active	running
kube-controller-manager.service	c576b883.../192.168.64.2	active	running
kube-kubelet.service			c576b883.../192.168.64.2	active	running
kube-proxy.service				c576b883.../192.168.64.2	active	running
kube-scheduler.service			c576b883.../192.168.64.2	active	running

kubectl get nodes:
NAME           	LABELS         STATUS
k8solo-01		node=worker1   Ready

````



Usage
------------

You're now ready to use Kubernetes cluster.

Some examples to start with [Kubernetes examples](http://kubernetes.io/docs/samples/).

Other CoreOS VM based Apps for macOS
-----------
* Kubernetes Cluster (master + 2 nodes) CoreOS VM App can be found here [Kube-Cluster for OS X](https://github.com/TheNewNormal/kube-cluster-osx).

* Standalone CoreOS VM version App can be found here [CoreOS macOS](https://github.com/TheNewNormal/coreos-osx).

* CoreOS Cluster one App can be found here [CoreOS-Vagrant Cluster](https://github.com/rimusz/coreos-osx-cluster).

## Contributing

**Corectl App** is an [open source](http://opensource.org/osd) project release under
the [Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0),
hence contributions and suggestions are gladly welcomed! 
