CoreOS-Vagrant Kubernetes Solo GUI for OS X
============================

![k8s-solo](k8s-singlenode.png)

`CoreOS-Vagrant Kubernetes Solo GUI for Mac OS X` is a Mac Status bar App which works like a wrapper around [coreos-vagrant](https://github.com/coreos/coreos-vagrant) command line tool and bootstraps Kubernetes on one standalone  machine.

Fully supports etcd2 in all CoresOS channels. 


[CoreOS](https://coreos.com) is a Linux distribution made specifically to run [Docker](https://www.docker.io/) containers.
[CoreOS-Vagrant](https://github.com/coreos/coreos-vagrant) is made to run on VirtualBox and VMWare VMs.

![CoreOS-Vagrant-Kubernetes-Solo-GUI](coreos-vagrant-k8s-solo-gui.png "CoreOS-Vagrant-Kubernetes-Solo-GUI")

Download
--------
Head over to the [Releases Page](https://github.com/rimusz/coreos-osx-gui-kubernetes-solo/releases) to grab the latest release.


How to install
----------

Required software:
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads), [Vagrant](http://www.vagrantup.com/downloads.html) and [iTerm 2](http://www.iterm2.com/#/section/downloads)
* Open downloaded App dmg file and drag it e.g. to your Desktop.
* Start the `CoreOS k8s Solo` App and from menu `Setup` and choose: `Initial setup of CoreOS-Vagrant k8s Solo`

The install will do the following:

* All dependent files/folders will be put under `coreos-k8s-solo` folder in the user's home folder
* It will clone latest coreos-vagrant from git
* user-data files will have fleet, etcd and flannel set
* VM machine will be set with IP `172.19.17.99`
* It will download latest vagrant VBox and run `vagrant up` to initialise VM
* When you first time install or do 'Up' after destroying k8s Solo setup, k8s binary files (with the version which was available when the App was built) get copied to CoreOS VM, this speeds up Kubernetes setup. To update Kubernetes just run from menu 'Updates' - Update Kubernetes and OS X kubectl.
* It will install `fleetctl, etcdctl and kubectl` to `~/coreos-k8s-solo/bin/`
* Kubernetes services will be installed with fleet units which are placed in `~/coreos-k8s-solo/fleet`, this allows very easy updates to fleet units if needed.
* Also [DNS Add On](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/cluster/addons/dns) will be installed

How it works
------------

Just start `CoreOS k8s Solo` application and you will find a small icon with the Kubernetes logo with (S) which means for Kubernetes Solo in the Status Bar.

* There you can `Up`, `Suspend`, `Halt`, `Reload` CoreOS vagrant VM
* Under `Up` (first does 'vagrant up') and `OS Shell` OS Shell (terminal) will have such environment set:
````
1) kubernetes master - export KUBERNETES_MASTER=http://172.19.17.99:8080
2) etcd endpoint - export ETCDCTL_PEERS=http://172.19.17.99:2379
3) fleetctl endpoint - export FLEETCTL_ENDPOINT=http://172.19.17.99:2379
4) fleetctl driver - export FLEETCTL_DRIVER=etcd
5) Path to ~/coreos-osx-solo/bin where etcdctl, fleetctl and kubernetes binaries are stored
````

* `Updates/Update Kubernetes and OS X kubectl` will update to latest version of Kubernetes.
* `Updates/Update OS X fleetctl, etcdclt and fleet units` will update fleetctl, etcdclt clients to the same versions as CoreOS VM run and to latest fleet units if the new version of App is used.
* `Updates/Force CoreOS update` will be run `sudo update_engine_client -update` on CoreOS VM.
* `Updates/Check updates for CoreOS vbox` will update CoreOS VM vagrant box.
*
* `SSH to k8solo-01` menu option will open VM shell
* `k8solo-01 cAdvisor` will open cAdvisor URL in default browser
* [Fleet-UI](http://fleetui.com) dashboard will show running fleet units and etc
* [Kubernetes-UI](https://github.com/GoogleCloudPlatform/kubernetes/tree/master/www) (contributed by [Kismatic.io](http://kismatic.io/)) will show nice Kubernetes Dashboard, where you can check Node, Pods, Replication Controllers and etc.


Example ouput of succesfull CoreOS + Kubernetes Solo install:

````
etcd cluster:
/coreos.com
/registry

fleetctl list-machines:
MACHINE		IP		METADATA
c576b883...	172.19.17.99	role=kube

fleetctl list-units:
UNIT									MACHINE				ACTIVE	SUB
fleet-ui.service				c576b883.../172.19.17.99	active	running
kube-apiserver.service			c576b883.../172.19.17.99	active	running
kube-controller-manager.service	c576b883.../172.19.17.99	active	running
kube-kubelet.service			c576b883.../172.19.17.99	active	running
kube-proxy.service				c576b883.../172.19.17.99	active	running
kube-scheduler.service			c576b883.../172.19.17.99	active	running

kubectl get nodes:
NAME           LABELS         STATUS
172.19.17.99   node=worker1   Ready

````




Usage
------------

You're now ready to use Kubernetes cluster.

Some examples to start with [Kubernetes examples](https://github.com/GoogleCloudPlatform/kubernetes/blob/master/examples/).

Other links
-----------
* Cluster one with Kubernetes CoreOS VM App can be found here [CoreOS-Vagrant Kubernetes Cluster GUI for OS X](https://github.com/rimusz/coreos-osx-gui-kubernetes-cluster).

* A standalone CoreOS VM version App can be found here [CoreOS-Vagrant GUI](https://github.com/rimusz/coreos-osx-gui).

* Cluster one without Kubernetes CoreOS VM App can be found here [CoreOS-Vagrant Cluster GUI](https://github.com/rimusz/coreos-osx-gui-cluster).


