# Service Director CL K8s Deployment Scenario

This Deployment file defines a standard Service Director Closed Loop deployment for kubernetes cluster with Closed Loop nodes, Apache kafka, a SNMP Adapter and a Service Director UI as well.

As a prerequisites for this deployment is a database and the Apache Kafka/Kafka-Zookeeper is required.


## Prerequisites
### 1. Deploy database

**If you have already deployed a database, you can skip this step!**

For this example, we bring up an instance of the `postgres` image in a K8S Pod, which is basically a clean PostgreSQL 11 image with a `sa` user ready for Service Director installation.

**NOTE**: If you are not using the K8S [postgres-db](../postgres-db) deployment, then you need to modify the [sd-cl-deployment.yaml](sd-cl-deployment.yaml) database related environments to point to the used database.

The following databases are available:

- Follow the deployment as described in [postgres-db](../postgres-db) directory.
- Follow the deployment as described in [enterprise-db](../enterprise-db) directory.
- Follow the deployment as described in [oracle-db](../oracle-db) directory.

**NOTE**: For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).


### 2. Deploy Apache Kafka and Kafka-Zookeeper
To deploy the Apache kafka and Kafka-Zookeeper, we use a Helm Chart to easily bring up the kafka services.

Follow the deployment as described in the [kafka-zookeper](../kafka-zookeeper) example before moving to the following part.


## SD Closed Loop Deployment

The [sd-cl-deployment.yaml](sd-cl-deployment.yaml) file contains the following deployments (k8s-Pods):

- `sd-ui`: UOC-based UI connected to `sd-sp` HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-snmp-adapter`: SD Closed Loop SNMP Adapter - [sd-cl-adapter-snmp](/docker/images/sd-cl-adapter-snmp)

The [sd-cl-deployment.yaml](sd-cl-deployment.yaml) file contains the following StatefulSets (k8s-Pods):

- `sd-sp`: HPE SD Closed Loop node, 2 replicas as a Statefulset - [sd-sp](/docker/images/sd-sp)

The following services are exposed to external ports in the k8s cluster:
- `sd-sp-nodeport`              -> `32518`: Service Director native UI
- `sd-ui-nodeport`              -> `32519`: Unified OSS Console (UOC) for primary Service Director
- `sd-snmp-adapter-nodeport`    -> `32162`: Closed Loop SNMP Adapter Service Director

In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [livenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check.

If you are using an external database, you need to adjust `SDCONF_activator_db_`-prefixed environment variables as appropriate for the `sd-cl-deployment`, also you need to make sure that your database is ready to accept connections before deploying the k8s [sd-cl-deployment](sd-cl-deployment.yaml).

**IMPORTANT**: The [sd-cl-deployment.yaml](sd-cl-deployment.yaml) file defines a docker registry examples (`hub.docker.hpecorp.net/cms-sd`) for the used images. This shall be changed to point to the docker registry where the docker images are located. E.g.: (`- image: hub.docker.hpecorp.net/cms-sd/sd-sp`)

**NOTE** A guidance in the amount of Memory and Disk for the sd-cl K8s deployment is that it requires 4GB RAM and minimum 25GB free Disk space on the assigned K8s nodes running the `sd-cl-deployment`. The amount of Memory of cause depends of other applications/pods running in same node.
In case K8s master and worker-node are in same host, like Minikube, then minimum 16GB RAM and 80GB Disk is required.

**IMPORTANT**: Before deploying Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run

    kubectl create namespace servicedirector


### Deploy CouchDB

HPE Service Director UI relies on CouchDB as its data persistence module, in order to deploy CouchDB we use a Helm Chart to easily bring up the services.

Follow the deployment as described in the [CouchDB](../couchdb) example before moving to the following part.


### Deploy Service Director Closed Loop

In order to deploy the Service Director Closed Loop K8s deployment, run:

    kubectl create -f sd-cl-deployment.yaml

```
statefulset.apps/sd-sp created
service/sd-sp-nodeport created
deployment.apps/sd-ui created
service/sd-ui-nodeport created
deployment.apps/sd-snmp-adapter created
service/sd-snmp-adapter-nodeport created
```

Validate when the deployed sd-cl applications/pods are ready (READY 1/1)

    kubectl get pods --namespace servicedirector

```
NAME                                   READY   STATUS    RESTARTS   AGE
postgres-deployment-746ff7cf67-ncsrc   1/1     Running   0          21m
kafka-0                                1/1     Running   0          20m
kafka-zookeeper-0                      1/1     Running   0          20m
sd-snmp-adapter-9d757c48c-hh89k        1/1     Running   0          16m
sd-sp-0                                1/1     Running   0          16m
sd-sp-1                                1/1     Running   0          12m
sd-ui-66cbc6d996-mcwkv                 1/1     Running   0          16m
sduicouchdb-couchdb-0                  1/1     Running   0          20m
```

When the SD HA applications are ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    http://<cluster_ip>:32518/activator/    (Service Director provisioning native UI)

    http://<cluster_ip>:32519/login         (Service Director UI)

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

    kubectl delete -f sd-cl-deployment.yaml --namespace servicedirector

```
statefulset.apps "sd-sp" deleted
service "sd-sp-nodeport" deleted
deployment.apps "sd-ui" deleted
service "sd-ui-nodeport" deleted
deployment.apps "sd-snmp-adapter" deleted
service "sd-snmp-adapter-nodeport" deleted
```

To delete the PostgreSQL and the Apache kafka and kafka-zookeepers, please follow the delete procedures as described in the respective examples.


## How to scale up/down closed loop nodes

The default sd-sp replicas is 2, if you want scale up/down the sd-sp nodes you can use the following command:

    kubectl scale statefulset sd-sp --replicas=X --namespace servicedirector

where X is the number of replicas you want to run.
