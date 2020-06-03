# Service Director HA K8S Deployment Scenario

This Deployment file defines a standard Service Director HA for kubernetes cluster with two provisioning nodes each having a Service Director UI on top as well.

As a prerequisites for this deployment is a database and the Apache Kafka/Kafka-Zookeeper is required.

## Prerequisites
### 1. Deploy database

**If you have already deployed a database, you can skip this step!**

For this example, we bring up an instance of the `postgres` image in a K8S Pod, which is basically a clean PostgreSQL 11 image with a `sa` user ready for Service Director installation.

**NOTE**: If you are not using the K8S [postgres-db](../postgres-db) deployment, then you need to modify the [sd-ha-deployment.yaml](sd-ha-deployment.yaml) database related environments to point to the used database.

The following databases are available:

- Follow the deployment as described in [postgres-db](../postgres-db) directory.
- Follow the deployment as described in [enterprise-db](../enterprise-db) directory.
- Follow the deployment as described in [oracle-db](../oracle-db) directory.

**NOTE**: For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).


## Service Director High Availability Deployment

The [sd-ha-deployment.yaml](sd-ha-deployment.yaml) file contains the following deployment (K8S-Pods):
- `sd-ui`: UOC-based UI connected to `sd-sp` Service Director - [sd-ui](/docker/images/sd-ui).

The [sd-ha-deployment.yaml](sd-ha-deployment.yaml) file contains the following StatefulSet (K8S-Pods):
- `sd-sp`: provisioning node, 2 replicas as a Statefulset - [sd-sp](/docker/images/sd-sp).

![SD-HA](SD-HA.png)

The following services are exposed to external ports in the K8S cluster:
- `sd-sp-nodeport`    -> `32514`: Service Director native UI.
- `sd-ui-nodeport`    -> `32516`: Unified OSS Console (UOC) for primary Service Director.

In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [livenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check. If you are using an external database, you may remove the `postgres-deployment` deployment and the `postgres-nodeport` from the file and adjust `SDCONF_hpsa_db_`-prefixed environment variables as appropriate for the `sd-sp` statefulset, also you need to make sure that your database is ready to accept connections before deploying the K8S [sd-ha-deployment.yaml](sd-ha-deployment.yaml).

**IMPORTANT**: The [sd-ha-deployment.yaml](sd-ha-deployment.yaml) file defines a docker registry examples (`hub.docker.hpecorp.net/cms-sd`) for the used images. This shall be changed to point to the docker registry where the docker images are located. E.g.: (`- image: hub.docker.hpecorp.net/cms-sd/sd-sp`)

**NOTE**: A guidance in the amount of Memory and Disk for the sd-ha K8S deployment is that it requires 2GB RAM and minimum 5GB free Disk space on the assigned K8S nodes running one replica of `sd-sp` and one replica of `sd-ui`. The amount of Memory of cause depends of other applications/pods running in same node. In case K8S master and worker-node are in same host, like Minikube, then minimum 8GB RAM and 20GB Disk is required.

**IMPORTANT**: Before deploying Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run

    kubectl create namespace servicedirector

### Deploy CouchDB

HPE Service Director UI relies on CouchDB as its data persistence module, in order to deploy CouchDB we use a Helm Chart to easily bring up the services.

Follow the deployment as described in the [CouchDB](../couchdb) example before moving to the following part.

### Deploy Service Director

In order to deploy the Service Director K8S deployment, run:

    kubectl create -f sd-ha-deployment.yaml

```
statefulset.apps/sd-sp created
service/sd-sp-nodeport created
deployment.apps/sd-ui created
service/sd-ui-nodeport created
```

Validate when the deployed sd-ha applications/pods are ready (READY 1/1):

    kubectl get pods --namespace servicedirector

```
NAME                     READY   STATUS    RESTARTS   AGE
sd-sp-0                  1/1     Running   0          6m32s
sd-sp-1                  1/1     Running   0          3m20s
sd-ui-68c57f448c-8t65w   1/1     Running   0          6m32s
```

When the SD HA applications are ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    http://<cluster_ip>:32514/activator/    (Service Director native UI)

    http://<cluster_ip>:32516/login         (Service Director UI)

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

In order to delete the Service Director HA Provisioning K8S deployment, run:

    kubectl delete -f sd-ha-deployment.yaml

```
statefulset.apps "sd-sp" deleted
service "sd-sp-nodeport" deleted
deployment.apps "sd-ui" deleted
service "sd-ui-nodeport" deleted
```


## Using a Service Director license

See in SD-SP [Using a Service Director License](../../deployments/sd-sp#using-a-service-director-license).


## How to scale up/down provisioner nodes

After you have created an HA-compatible cluster, if you want to scale up/down the SD-SP nodes you can use the following command:

    kubectl scale statefulset sd-sp --replicas=X --namespace servicedirector

where X is the number of replicas you want to run.
