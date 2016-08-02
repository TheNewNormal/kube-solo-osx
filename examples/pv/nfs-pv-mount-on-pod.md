# Accessing the local NFS server through a Persistent Volume

kube-cluster setups for you an NFS server on your local machine that can be accessed by the pods running inside the Kubernetes installation. This guide will show you how to point a Persistent Volume (PV) to to that NFS server and to use that PV to mount the shared filesystem inside your pods through a Persistent Volume Claim. This doesn't require that the CoreOS nodes mount the NFS shared filesystem.

## NFS running

Although this part is provided by kube-cluster, make sure that your /etc/exports has the following line:
```
/Users/<your_username> -network 192.168.64.0 -mask 255.255.255.0 -alldirs -maproot=root:wheel
```
and restart your nfs daemon to make sure it is running:
```
sudo nfsd restart
```

## Persistent Volume (PV) creation

If NFS is running, then use a Persistent Volume that connects to this NFS mount:

```
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv-nfs
  labels:
    type: nfs
spec:
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retained
  nfs:
    path: /Users/<your_username>/desired/path/to/mount
    server: corectld
```

Paste this on `pv_nfs.yml`, replace the `spec:nfs:pathp` for an adequate path you want mounted through this PV, and create the PV with `kubectl create -f pv_nfs.yml`. You can change of course options like the persistent volume reclaim policy or the total capacity that you wish to offer through this PV. Please see more details for those changes on the Kubernetes documentatio for [PVs](http://kubernetes.io/docs/user-guide/persistent-volumes/). Server `corectld` points automatically to your Mac, where you are running kube-cluster.

## Persistent Volume Claim (PVC) creation

Supposing that the PV was created and is working fine (you can check it with `kubectl describe pv/pv-nfs`), you can create a persistent volume claim that can connects to this PV. The PVC acts as an adaptor between the PV and the Pods, so that whichever logic was used to produce the PV, is abstracted from the Pod.

Copy and paste the following `yaml` code into a `pvc.yml` file:

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 15Gi
```

and then run `kubectl create -f pvc.yml`. This will create the PVC on your Kubernetes cluster, which should get bounded to the initially created PV if there are not other PVs in the system. You could add labels at both the PV and PVC to make sure that this PVC attaches to the previously created PV. Make sure that the storage requirement in the PVC (`spec:resources:requests:storage`) is below the amount set as capacity in the PV. Again, please check available options for resources and access modes in the Kubernetes documentation for PVC. 

## Accessing the PVC from a Pod (or Job/Replication controller)

PVCs are accessed from Pods/Jobs/RCs as any volume is. A minimal example would be:

```
kind: Pod
apiVersion: v1
metadata:
  name: mypod
  labels:
    name: frontendhttp
spec:
  containers:
    - name: myfrontend
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
      - mountPath: "/usr/share/nginx/html"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
       claimName: my-pvc
```

so pasting this yaml into a file named `nginx-pod-pvc.yml` and run `kubectl create -f nginx-pod-pvc.yml` should start a pod for you with nginx, mounting your PVC on `/usr/share/nginx/html` inside the running container. 
