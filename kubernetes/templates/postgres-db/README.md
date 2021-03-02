# PostgreSQL DB deployment example for supporting Service Director Kubernetes deployment

**NOTE** For production environments you should either use an external, non-containerized database or create an image of your own.

This is a postgres-db Kubernetes (K8S) deployment example for supporting the Service Director Kubernetes deployment for the [Helm Chart](/kubernetes/helm). It deploys the PostgreSQL container into a kubernetes cluster Pod.

It will create a Pod with an PostgreSQL database prepared to install Service Director as recommended. There is a `sa` user (password is `secret`) with all the privileges required for a Service Activator installation. The image also supports health check which is used for a [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)

PostgreSQL requires a volume in order to store the database files, therefore a PersistentVolume and PersistentVolumenClaim has been added to the deployment file. The storage values can be increased to adjust the storage data to your requirements, the storage path can be change to create the volume in an alternative folder that suits you.

**NOTE**: A guidance in the amount of Memory and Disk for the PostgreSQL database K8S deployment is that it requires 2GB RAM and minimum 512M free Disk space on the assigned K8S Node. The amount of Memory of course depends of other applications/pods running in same node. In case K8S master and worker-node are in same host, like Minikube, then minimum 5GB RAM is required.

**IMPORTANT**: Before deploying Service Director a namespace with the name "sd" must be created. In order to generate the namespace, run:

    kubectl create namespace sd

**IMPORTANT**: PostgreSQL needs to store its data on persistent storage, therefore a persistent volume must be available. 
A persistent volume (PV) is a cluster resource that you can use to store data for a pod and it persists beyond the lifetime of that pod. The PV is backed by networked storage system such as  NFS. You can find more info [here](../../docs/PersistentVolumes.md)  on how to setup to your cluster for automatic creation of PV.

Previously to this step you need to generate some persistent volumes in Kubernetes. Some Kubernetes distributions as Minikube or MicroK8S run in a single node and supports PV of type hostPath out-of-the-box. These PersistentVolumes are mapped to a directory inside the running Kubernetes instance and the provisioning is managed automatically, therefore the PV will be generated for your PostgreSQL pods and you don't need to do the setup that follow.

If you have configured dynamic provisioning on your cluster, such that all claims are dynamically provisioned if no storage class is specified, you can also skip the following step.

This example will explain how to create a hostPath PersistentVolume. Kubernetes supports hostPath for development and testing on a single-node cluster but in a production cluster, you would not use hostPath.

To use a local volume, the administrator must create the directory in which the volume will reside and ensure that the permissions on the directory allow write access. Use the following commands to set up the directory:

    mkdir /data/postgres-data-volume
    chmod -R 777 /data/postgres-data-volume

Where "/data/postgres-data-volume" is the complete path to the directory in which the volume will reside. If you want to use a different folder you have to modify the file [pv.yaml](./pv.yaml).

Then you have to deploy the file [pv.yaml](./pv.yaml). In order to create the persistent volume run:

    kubectl create -f pv.yaml

## Usage

In order to deploy the PostgreSQL for Service Director in a single K8S Pod, run

    kubectl create -f postgresdb-deployment.yaml

```
persistentvolumeclaim/postgres-data-pvc created
deployment.apps/postgres-deployment created
service/postgres-nodeport created
```

Validate when the deployed postgres application/pod is ready (READY 1/1)

    kubectl get pods --namespace sd

```
NAME                                  READY   STATUS    RESTARTS   AGE
postgres-deployment-bf7f77699-x9gqt   1/1     Running   0          11s
```

When the application is ready, then the deployed PostgreSQL service are exposed with the following:

```
Hostname: <cluster_ip>
Port: 30021
SID: HPSA
```

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

If you use the database to support the [Helm Chart](/kubernetes/helm), into the same kubernetes cluster, you can define the container env in the deployment to point to this db-instance hostname by using the kubernetes service name `postgres-nodeport`:

```yaml
containers:
  - image: hub.docker.hpecorp.net/cms-sd/sd-sp
    imagePullPolicy: Always
    name: sd-sp
    env:
      - name: SDCONF_activator_db_vendor
        value: PostgreSQL
      - name: SDCONF_activator_db_hostname
        value: postgres-nodeport
      - name: SDCONF_activator_db_instance
        value: sa
      - name: SDCONF_activator_db_user
        value: sa
      - name: SDCONF_activator_db_password
        value: secret
```

To delete the PostgreSQL, run:

    kubectl delete -f postgresdb-deployment.yaml

```
persistentvolumeclaim "postgres-data-pvc" deleted
deployment.apps "postgres-deployment" deleted
service "postgres-nodeport" deleted
```
