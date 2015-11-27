Kubernetes Solo cluster for OS X
============================

![k8s-solo](k8s-singlenode.png)

Zero to Kubernetes development environment
---------------

**Kube-Solo for Mac OS X** is a Mac Status bar App which works like a wrapper around the [coreos-xhyve](https://github.com/coreos/coreos-xhyve) command line tool and bootstraps Kubernetes on a standalone [CoreOS](https://coreos.com) VM machine.

Includes [Helm](https://helm.sh) - The Kubernetes Package Manager


![Kube-Solo](kube-solo-osx.png "Kubernetes-Solo")

Download
--------
Head over to the [Releases Page](https://github.com/rimusz/kube-solo-osx/releases) to grab the latest release.


How to install Kube-Solo
----------

**WARNING**
 -----------
  - You must be running **OS X 10.10.3** Yosemite or later and 2010 or later Mac for this to work.

  - If you are, or were, running any version of VirtualBox, prior to 4.3.30 or 5.0,
and attempt to run xhyve your system will immediately crash as a kernel panic is
triggered. This is due to a VirtualBox bug (that got fixed in newest VirtualBox
versions) as VirtualBox wasn't playing nice with OSX's Hypervisor.framework used
by [xhyve](https://github.com/mist64/xhyve). 


###Install:

Start the `Kube-Solo` and from menu `Setup` choose `Initial setup of Kube-Solo` and the install will do the following:

* All dependent files/folders will be put under `kube-solo` folder in the user's home folder e.g /Users/someuser/kube-solo
* User's Mac password will be stored in `OS X KeyChain`, it will be used for `sudo` command which needs to be used starting VM with xhyve
* ISO images are stored under ~/.coreos-xhyve/imgs and symlinked to it from ~/kube-solo/imgs
That allows to share the same images between different coreos-xhyve Apps and also speeds up this App's reinstall
* user-data file will have fleet, etcd, and Docker Socket for the API enabled
* Will download latest CoreOS ISO image and run `xhyve` to initialise VM 
* When you first time do install or 'Up' after destroying k8s Solo setup, k8s binary files (with the version which was available when the App was built) get copied to CoreOS VM, this speeds up Kubernetes setup. To update Kubernetes just run from menu 'Updates' - Update Kubernetes and OS X kubectl.
* It will install `fleetctl, etcdctl and kubectl` to `~/kube-solo/bin/`
* Kubernetes services will be installed with fleet units which are placed in `~/kube-solo/fleet`, this allows very easy updates to fleet units if needed.
* [Fleet-UI](http://fleetui.com) via unit file will be installed to check running fleet units
* [Kubernetes UI](http://kubernetes.io/v1.0/docs/user-guide/ui.html) will be instlled as an add-on
* Also [DNS Add On](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/cluster/addons/dns) will be installed
* Via assigned static IP (it will be shown in first boot and will survive VM's reboots) you can access any port on CoreOS VM
* Root persistant disk for VM will be created and mounted to `/` so data will survive VM reboots. 

How it works
------------

Just start `Kube-Solo` application and you will find a small icon of Kubernetes logo with `S` in the Status Bar.

* There you can `Up`, `Halt`, `Reload` CoreOS VM
* `SSH to k8solo-01` will open VM shell
* `Attach to VM's console` will open VM console
* Under `Up` OS Shell will be opened when VM boot finishes up and it will have such environment pre-set:

````
1) kubernetes master - export KUBERNETES_MASTER=http://192.168.64.xxx:8080
2) etcd endpoint - export ETCDCTL_PEERS=http://192.168.64.xxx:2379
3) fleetctl endpoint - export FLEETCTL_ENDPOINT=http://192.168.64.xxx:2379
4) fleetctl driver - export FLEETCTL_DRIVER=etcd
5) Path to ~/kube-solo/bin where etcdctl, fleetctl and kubernetes binaries are stored
````

* `Updates/Update Kubernetes and OS X kubectl` will update to latest version of Kubernetes.
* `Updates/Update OS X fleetctl, etcdclt and fleet units` will update fleetctl, etcdclt clients to the same versions as CoreOS VM run and to latest fleet units if the new version of App is used.
* `Fetch latest CoreOS ISO` will download latest ISO file of CoreOS VM.
*
* `SSH to k8solo-01` menu option will open VM shell
* `k8solo-01 cAdvisor` will open cAdvisor URL in default browser
* [Fleet-UI](http://fleetui.com) dashboard will show running fleet units and etc
* [Kubernetes-UI](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/www) (contributed by [Kismatic.io](http://kismatic.io/)) will show nice Kubernetes Dashboard, where you can check Nodes, Pods, Replication and Service Controllers and etc.


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
NAME           LABELS         STATUS
192.168.64.2   node=worker1   Ready

````



Usage
------------

You're now ready to use Kubernetes cluster.

Some examples to start with [Kubernetes examples](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/examples/).

Other links
-----------
* Cluster one with Kubernetes CoreOS VM App can be found here [CoreOS Kubernetes Cluster for OS X](https://github.com/rimusz/coreos-osx-kubernetes-cluster).

* Standalone CoreOS VM version App can be found here [CoreOS OS X](https://github.com/TheNewNormal/coreos-osx).

* CoreOS Cluster one App can be found here [CoreOS-Vagrant Cluster](https://github.com/rimusz/coreos-osx-cluster).
