# Service Director HA K8s Deployment Scenario

This Deployment file defines a standard Service Director HA for kubernetes cluster with two provisioning nodes each having a Service Director UI on top as well.

As Service Director requires an external database as well, for the purpose of this example we are bringing up an instance of the `EnterpriseDB lite` image in a K8s Pod, which is basically a clean Enterprise DB image with an `enterprisedb` user ready for Service Director installation. For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official EnterpriseDB's [docker-images](https://containers.enterprisedb.com).

The [sd-ha-edb-deployment.yaml](sd-ha-edb-deployment.yaml) file contains the following deployments (k8s-Pods):

- `enterprisedb-deployment`: fulfillment database server
- `sd-ui`: UOC-based UI connected to `sd-sp` Service Director - [sd-ui](/docker/images/sd-ui)

The [sd-ha-edb-deployment.yaml](sd-ha-edb-deployment.yaml) file contains the following statefulsets (k8s-Pods):

- `sd-sp`: provisioning node - [sd-sp](/docker/images/sd-sp)

![SD-HA](SD-HA.png)

The following services are exposed to external ports in the k8s cluster:
- `enterprisedb-nodeport`   -> `30021`: EnterpriseDB listener port
- `sdsp-nodeport`           -> `32514`: Service Director native UI
- `sdui-nodeport`           -> `32516`: Unified OSS Console (UOC) for primary Service Director

In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [k8s initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).
The initContianers are not mandatory.
Further it adds k8s [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [livenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check. If you are using an external database, you may remove the `enterprisedb-deployment` deployment and the `enterprisedb-nodeport` from the file and adjust `SDCONF_hpsa_db_`-prefixed environment variables as appropriate for the `sd-sp` statefulset, also you need to make sure that your database is ready to accept connections before deploying the k8s [sd-ha-deployment](sd-ha-edb-deployment.yaml).

**IMPORTANT**: The [sd-ha-edb-deployment.yaml](sd-ha-edb-deployment.yaml) file defines a docker registry examples (`hub.docker.hpecorp.net/cms-sd`) for the used images. This shall be changed to point to the docker registry where the docker images are located. E.g.: (`- image: hub.docker.hpecorp.net/cms-sd/sd-sp`)

**NOTE**: A guidance in the amount of Memory and Disk for the sd-ha K8s deployment is that it requires 2GB RAM and minimum 5GB free Disk space on the assigned K8s nodes running one replica of `sd-sp` and one replica of `sd-ui`. For the node running the `enterprisedb-deployment` it requires 4GB RAM and minimum 12GB Disk Size. The amount of Memory of cause depends of other applications/pods running in same node. In case K8s master and worker-node are in same host, like Minikube, then minimum 8GB RAM and 20GB Disk is required.

**IMPORTANT**: Before deploying Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run

    kubectl create namespace servicedirector

**IMPORTANT**: Before deploying Service Director a Persistent Volume in Kubernetes must be created for EnterpriseDB to store the database files. This an example of a local storage PV in a single node K8S cluster:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
    name: edb-data-volume
    labels:
    type: local
spec:
    capacity:
    storage: 3Gi
    accessModes:
    - ReadWriteOnce
    hostPath:
    path: "/mnt/edb-data-pvc"
---
```


### Deploy CouchDB

HPE Service Director UI relies on CouchDB as its data persistence module, in order to deploy CouchDB we use a Helm Chart to easily bring up the services.

Follow the deployment as described in the [CouchDB](../couchdb) example before moving to the following part.


### Deploy Service Director 

In order to deploy the Service Director K8s deployment, run

    kubectl create -f sd-ha-edb-deployment.yaml

```
persistentvolumeclaim/edb-data-pvc created
secret/logintoken created
configmap/edb-initconf created
deployment.apps/enterprisedb-deployment created
service/enterprisedb-nodeport created
statefulset.apps/sd-sp created
service/sdsp-nodeport created
deployment.apps/sd-ui created
service/sdui-nodeport created
```

Validate when the deployed sd-ha applications/pods are ready (READY 1/1)

    kubectl get pods --namespace servicedirector

```
NAME                                       READY   STATUS    RESTARTS   AGE
enterprisedb-deployment-7c4b89d6cc-smhvp   1/1     Running   0          10m
sd-sp-0                                    1/1     Running   0          10m
sd-sp-1                                    1/1     Running   0          10m
sd-ui-c48649b49-cfjhs                      1/1     Running   0          10m
sduicouchdb-couchdb-0                      1/1     Running   0          12m
```

When the SD HA applications are ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    http://<cluster_ip>:32516/login         (Service Director UI)

    http://<cluster_ip>:32514/activator/    (Service Director native UI)

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`

In order to delete the Service Director HA Provisioning K8s deployment, run

    kubectl delete -f sd-ha-edb-deployment.yaml

```
persistentvolumeclaim "edb-data-pvc" deleted
secret "logintoken" deleted
configmap "edb-initconf" deleted
deployment.apps "enterprisedb-deployment" deleted
service "enterprisedb-nodeport" deleted
statefulset.apps "sd-sp" deleted
service "sdsp-nodeport" deleted
deployment.apps "sd-ui" deleted
service "sdui-nodeport" deleted
```


## How to scale up/down provisioner nodes

After you have created an HA-compatible cluster, if you want to scale up/down the SD-SP nodes you can use the following command:

    kubectl scale statefulset sd-sp --replicas=X --namespace servicedirector

where X is the number of replicas you want to run.


## How to scale up/down UI nodes

After you have created an HA-compatible cluster, if you want to scale up/down the SD-UI nodes you can use the following command:

    kubectl scale deployment sd-ui --replicas=X --namespace servicedirector

where X is the number of replicas you want to run.
