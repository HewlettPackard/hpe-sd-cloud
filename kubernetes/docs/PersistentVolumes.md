
**Table of Contents**

  - [Introduction](#introduction)
    - [Provisioning](#provisioning)
    - [Binding](#binding)
    - [Using](#using)
    - [Releasing](#releasing)
    - [Reclaiming](#reclaiming)
  - [Types of Persistent Volumes](#types-of-persistent-volumes)
  - [Claims As Volumes](#claims-as-volumes)
  - [Dynamic Volume Provisioning](#dynamic-volume-provisioning)
  - [Persistent Volumes in multi node configurations](#persistent-volumes-in-multi-node-configurations)
  - [Persistent Volumes in single node configurations](#persistent-volumes-in-single-node-configurations)
  - [Local Volumes in K8s nodes](#local-volumes-in-k8s-nodes)

## Introduction

Files in a container are temporary, when a container crashes or stops the data is lost but you can use storage volumes to persist some data used by the container. Kubernetes provides some objects called Persistent Volumes to deal with this storage requirements.

The `PersistentVolume` (PV) object abstracts details of how storage is provided in a Kubernetes cluster.  A `PersistentVolume` (PV) is a piece of storage in the cluster that has been provisioned but have a lifecycle independent of the pod that uses the PV. This object contains the details of the implementation of the storage as NFS, cloud-provider-specific storage, etc.

A `PersistentVolumeClaim` (PVC) is a request for storage, pods request the storage using a PVC and PVCs consume those PV resources. Those claims can request specific size and access modes (e.g, can be mounted once read/write or many times read-only).



The interaction between PVs and PVCs follows this lifecycle:

### Provisioning

A cluster administrator will create a number of PVs with the details of the real storage which is available for use by cluster objects.

### Binding

A `PersistentVolumeClaim` is created with a request of a specific amount of storage requested and with certain access modes. Kubernetes finds a matching PV (if possible), and binds them together.

A PersistentVolumeClaim  will remain unbound indefinitely if a matching volume does not exist but that claim will be bound as matching volumes become available. For example, a cluster provisioned with several 10Gi PVs would not match a PVC requesting 20Gi. The PVC will be bound when a 20Gi PV is added to the cluster.

### Using

Pods use PVC as volumes, once a pod has a PVC bound to a PV, the PV belongs to the pod for as long as it is needed. Pods and access their claimed PVs by including a persistentVolumeClaim in their volumes block.

### Releasing

In order to release the PV and the storage associated, the PVC objects must be deleted. The volume is considered "released" when the PVC is deleted, but it is not yet available for another claim. The data remains on the volume which must be handled according to the "policy".

### Reclaiming

The reclaim policy for a `PersistentVolume` tells the cluster what to do with the data's volume after it has been released. The data in the volumes can either be Retained or Delete.

Delete removes both the PersistentVolume object from Kubernetes, as well as the data in the physical infrastructure, such as an NFS, EBS, etc.

Retain policy allows for manual reclamation of the resource: when the PVC is deleted, the PersistentVolume still exists and the volume is considered `released`. But it is not yet available for another claim because the data remains on the volume. Therefore With the Retain policy, when the PersistentVolumeClaim is deleted, the corresponding PersistentVolume is moved to the Released phase, where all of its data can be manually recovered. You can reuse the PV executing the following manual steps:

- Manually delete the content of the share using e.g. rm -Rf /exports_pv/volume/*
- Remove the reference to the previous claim in the PV wih the command: kubectl patch pv <your-pv-name> --patch '{"spec": {"claimRef": null }}'

## Types of Persistent Volumes

 There are different types of volumes you can use in a Kubernetes pod:

 - Local storage (emptyDir and hostPath) they are attached to the pod, stored either in RAM or in persistent storage on the lcoal filesystem. Their content is available as long as the pod is running. When the pod is removed, the data is lost

- Cloud volumes (as NFS, awsElasticBlockStore, azureDiskVolume, and gcePersistentDisk) , the volume is placed outside of the pod. To connect the pod to the provider, the storage connection must be setup.

 There is a special type called "hostPath" volume, which mounts a directory from the host node's filesystem. It offers a quick option for testing in a non production cluster environment where there is only one node, but local storage is not supported in any way and will not work in a multi-node cluster.

### Phase

A volume will be in one of the following phases:

* Available -- a free resource that is not yet bound to a claim
* Bound -- the volume is bound to a claim
* Released -- the claim has been deleted, but the resource is not yet reclaimed by the cluster
* Failed -- the volume has failed its automatic reclamation

The CLI will show the name of the PVC bound to the PV.


## Claims As Volumes

The cluster finds the claim in the pod's namespace and uses it to get the `PersistentVolume` backing the claim.  The volume is then mounted to the host and into the pod.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: mycontainer
      image: dockerfile/nginx
      volumeMounts:
      - mountPath: "/data/pv1/"
        name: myvolume
  volumes:
    - name: myvolume
      persistentVolumeClaim:
        claimName: theclaim
```


## Dynamic Volume Provisioning

Dynamic volume provisioning allows storage volumes to be created on-demand. Without dynamic provisioning you have to create manually storage volumes, and then create PersistentVolume objects that maps them. The dynamic provisioning feature eliminates the need to pre-provision storage and it will automatically provision storage when it is requested.

The implementation of a dynamic volume provisioning is based on the object StorageClass that specifies a volume plugin that provisions the storage needed. To enable dynamic provisioning one or more StorageClass objects must be created including which provisioner should be used and what parameters should be passed to that provisioner. In this example a NFS provisoner is used :


```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: example.com/nfs
parameters:
  archiveOnDelete: "false"
```

This Storageclass needs one or more NFS shares already created and a pod running a provisioner container (quay.io/kubernetes_incubator/nfs-provisioner:v1.0.8) that will listen for storage requests and then create paths and export them over nfs for use by your workloads.



## Persistent Volumes in multi node configurations

Production environments have Kubernetes clusters with several cluster nodes and the need to store persistent data is requirement in most cases. The focus of this paragraph is about how to leverage persistent storage in the Service Director deployment pods using [Persistent Volumes](./PersistentVolumes.md#introduction). It will include examples for the following storage type NFS and awsElasticBlockStore.

Service Director deployment pods will request persistent storage via the [Persistent Volume Claims](./PersistentVolumes.md#introduction) objects and they contain information about what characteristics the storage must have,as the size or the access mode. Once the Service Director deployment pods create a PVC there is a process of searching for a suitable PV defined in the Kubernetes cluster that matches the request.

### Persistent Volumes in multi node configurations, NFS example
As a first example we will use a Network File System (NFS) share as a storage infrastructure for the K8S cluster. In order to run this example an NFS server already configured and running is needed. If we configure the storage for a full Service Director setup we will need a network shared storage folder, once created the /etc/exports file should include something like this:

    /sharedfolders/dir1 mycluster.name.com(rw,sync,all_squash)

Where mycluster.name.com is the name of your K8S cluster , you can also provide the IP address. The folder created is called /sharedfolders/dir1

Kubernetes doesn't provide an internal NFS provisioner, but an external provisioner can be used. In order to use one in our cluster we need to create and deploy a yaml file that contains a NFS provisioner that connects Kubernetes with the NFS server:

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-provisioner
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: nfs-provisioner
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-provisioner
    spec:
      containers:
        - name: nfs-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          volumeMounts:
            - name: nfs-my-volume
              mountPath: /nfspersistentvolume
          env:
            - name: PROVISIONER_NAME
              value: nfsprovisioner1
            - name: NFS_SERVER
              value: mynfs.server.com
            - name: NFS_PATH
              value: /sharedfolders/dir1
      volumes:
        - name: nfs-my-volume
          nfs:
            server: mynfs.server.com
            path: /sharedfolders/dir1
```

Once the yaml file is created the resource will be available to the cluster by running:

    kubectl create -f provisioner.yaml

Where provisioner.yaml is the name for the file created.

To enable dynamic provisioning, a cluster administrator needs to pre-create one or more StorageClass objects for pods. Now we need to create a StorageClass that will be used by the Service Director deployment pods to request storage (using a PVC), the following manifest creates a storage class `managed-nfs-storage` which provisions NFS persistent disks:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: nfsprovisioner1
parameters:
  archiveOnDelete: "false"
```

Once the yaml file is created the resource will be available to the cluster by using:

    kubectl create -f mystorageclass.yaml

Where mystorageclass is the name for the file created in the previous step. Now you can start the SD Helm chart example using the following parameters:

 - Kafka and Zookeeper:
     kafka.persistence.enabled=true
     kafka.persistence.storageClass=managed-nfs-storage

 - CouchDB:
     couchdb.persistentVolume.enabled=true
     couchdb.persistentVolume.storageClass=managed-nfs-storage

 - Redis:
     redis.master.persistence.enabled=true
     redis.master.persistence.storageClasss=managed-nfs-storage

- Database deployment:
     Add the following line to the DB yaml file before deployment
     storageClassName: managed-nfs-storage



### Persistent Volumes in multi node configurations, awsElasticBlockStore example

As a second example we will use awsElasticBlockStore as a storage infrastructure for the K8S cluster. In order to run this example the underlying infrastructure must be configured for AWS Elastic Block Store and the cluster must be able to execute AWS calls to create ec2 type volumes.

First of all we need to create a StorageClass that will be used by the Service Director deployment pods to request storage (using a PVC):

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: managed-aws-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  zone: us-east-1d
allowVolumeExpansion: true
volumeBindingMode: Immediate
reclaimPolicy: Retain
```

The parameters field will send volume options to the provisioner. In this case, we are telling AWS about the type of volume "gp2" (General Purpose SSD) and "zone" to restrict the zone where the volume lives in. The parameters you specify will depend on the type of AWS storage that you are using.

Once the yaml file is created the resource will be available to the cluster by using:

    kubectl create -f mystorageclass.yaml

Where mystorageclass.yaml is the name for the file created in the previous step. Now you can start the SD Helm chart example,with persistence activated, using the following parameters:

 - Kafka and Zookeeper:
     kafka.persistence.enabled=true
     kafka.persistence.storageClass=managed-aws-storage

 - CouchDB:
     couchdb.persistentVolume.enabled=true
     couchdb.persistentVolume.storageClass=managed-aws-storage

 - Redis:
     redis.master.persistence.enabled=true
     redis.master.persistence.storageClasss=managed-aws-storage

- Database deployment:
     Add the following line to the DB yaml file before deployment
     storageClassName: managed-aws-storage

Anytime the SD deployment pods need some storage the provisioner will execute a command similar to this:

     aws ec2 create-volume --availability-zone=eu-east-1d --size=xxxxx --volume-type=gp2


## Persistent Volumes in single node configurations

Some single-node Kubernetes distros as Minikube or MicroK8S inckude a dynamic storage controller that runs as part of its deployment. This manages provisioning of hostPath volumes in local storage.

This feature allows the deployments without the need to include or create PVs as they will be created on the fly for the PVCs that request it: the controller generates a PersistentVolume object of type hostpath dynamically when the controller receives a storage request.

Minikube has its own provisioner "k8s.io/minikube-hostpath" and it creates any storage claim under the /tmp folder, its storageclass is the following:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: standard
provisioner: k8s.io/minikube-hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

It is set as the default StorageClass which means that any PVC created will be bound to a new PV created automatically under the /tmp folder, it is also set "reclaimPolicy: Delete" which means the folder containing the pod's data will be deleted when a pod and its PVC are uninstalled.

When Service Director deployment pods run in these Kuberentes clusters any Persistent Volume Claim will be handled automatically and the PV needed will be created as a subfolder of the /tmp  folder. Therefore there is no need to add extra information or create additional PVs to the SD deployment when persistence is enabled in the pods.

Therefore you can start the SD Helm chart example,with persistence activated, using the following parameters:

 - Kafka and Zookeeper:
     kafka.persistence.enabled=true

 - CouchDB:
     couchdb.persistentVolume.enabled=true

 - Redis:
     redis.master.persistence.enabled=true

- Database deployment:
    Nothing additional is needed in the DB yaml file before deployment



## Local Volumes in K8s nodes

If you are running a single node K8S cluster you can use the local storage for the PV claims, in order to support dynamic provisioning you have to install a provisioner. There are several third party providers to accomplish this, the following one is provided as an example.

The next helm chart will create a hostpath-provisioner deployment on a Kubernetes, which dynamically provisions Kubernetes HostPath Volumes.

To install the chart you have to add the repo to helm:

    helm repo add rimusz https://charts.rimusz.net

then you have to update the repos:

    helm repo update

now you can install the helm chart:

    helm install hostpath-provisioner  rimusz/hostpath-provisioner --namespace kube-system --set NodeHostPath=/tmp/hostpath

This will install a provisioner called "hostpath-provisioner" and a default StorageClass called "hostpath" that will be used to bind to PVCs. There is an extra parameter called NodeHostPath, this parameter points to the host folder where the PVs subfolders will be created. It is recommended to create the folder in advance and assign some permissions.

Now you can start the SD Helm chart example, with persistence activated, using the following parameters:

 - Kafka and Zookeeper:
     kafka.persistence.enabled=true

 - CouchDB:
     couchdb.persistentVolume.enabled=true

 - Redis:
     redis.master.persistence.enabled=true

- Database deployment:
     Nothing additional is needed in the DB yaml file before deployment

