# Service Director Helm chart Deployment Scenario

This folder defines a Helm chart and repo for all deployment scenarios of Service Director as service provisioner, Closed Loop or high availability. Deployment for Closed Loop nodes must include kubernetes cluster with, Apache kafka, a SNMP Adapter and a Service Director UI as well. Deployment of Service Director as service provisioner nodes must include kubernetes cluster with Service Director UI.

The subfolder [/repo](./repo) contains all the files of a Helm chart repository, that houses an [index.yaml](./repo/index.yaml) file and the packaged charts.

The subfolder [/chart](./chart) contains the files of the Helm chart, with the following files:

- values.yaml:                              `provides the data passed into the chart`
- Chart.yaml:                               `it contains the chart's metainformation`
- requirements.yaml:                        `lists the dependencies that your chart needs`
- requirements.lock:                        `lists the exact versions of dependencies`
- /templates/:                              `SD deployment files`
- /templates/ELK/:                          `support files for the ELK example`
- /templates/prometheus/:                   `support files for the Prometheus example`
- /templates/redis/:                        `support files for the Redis deployment`
- /charts/:                                 `additional helm charts, needed as a dependency`

As prerequisites for this deployment a database, a namespace and two persistent volumes are required.


## Prerequisites

### 1. Deploy database

**If you have already deployed a database, you can skip this step!**

For this example, we bring up an instance of the `postgres` image in a K8S Pod, which is basically a clean PostgreSQL 11 image with a `sa` user ready for Service Director installation.

**NOTE**: If you are not using the K8S [postgres-db](../postgres-db) deployment, then you need to modify the [values.yaml](./chart/values.yaml) database related environments to point to the used database.

The following databases are available:

- Follow the deployment as described in [postgres-db](../postgres-db) directory.
- Follow the deployment as described in [enterprise-db](../enterprise-db) directory.
- Follow the deployment as described in [oracle-db](../oracle-db) directory.

**NOTE**: For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).


### 2. Namespace

Before deploying Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run

    kubectl create namespace servicedirector


## SD Closed Loop Deployment

In order to install SD Closed Loop example using Helm, the SD Helm repo must be added using the following command:

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add couchdb https://apache.github.io/couchdb-helm
    helm repo add sd-chart-repo https://raw.github.hpe.com/hpsd/sd-cloud/master/kubernetes/helm/sd-chart/repo/

Then the following command must be executed to install Service Director :

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector

Where `<image-tag>` is the Service Director version you want to install, if this parameter is omitted then the latest image available is used by default.

The value `<repo>` is the Docker repo where Service Director image is stored, usually this value is "hub.docker.hpecorp.net/cms-sd". If this parameter is not included then the local repo is used by default.

The Kubernetes cluster now contains the following pods:

- `sd-cl`:              HPE SD Closed Loop nodes, processing assurance and non-assurance requests - [sd-sp](../../docker/images/sd-sp)
- `sd-ui`:              UOC-based UI connected to HPE Service Director - [sd-ui](../../docker/images/sd-ui)
- `sd-snmp-adapter`:    SD Closed Loop SNMP Adapter - [sd-sp](../../docker/images/sd-cl-adapter-snmp)
- `kafka-service`:      Kafka service
- `zookeeper-service`:  Zookeeper service
- `sd-helm-couchdb`:    CouchDB database
- `redis-master`:    Redis database

Some of the containers won't deploy in your cluster depending on the parameters chosen during helm chart startup.

The following services are also exposed to external ports in the k8s cluster:

- `sd-cl` -> `32518`:           Service Director Closed Loop node native UI
- `sd-cl-ui` -> `32519`:           Unified OSS Console (UOC) for Service Director
- `sd-snmp-adapter` -> `32162`: Closed Loop SNMP Adapter Service Director

The following table lists common configurable parameters of the chart and their default values. See [values.yaml](./chart/values.yaml) for all available options.

| Parameter                                 | Description                                                       | Default   |
|-------------------------------------------|-------------------------------------------------------------------|-----------|
| `sdimage.install_assurance`               | Set to false to disable Closed Loop                               | `true`    |
| `couchdb.enabled`                         | Set to false to disable CouchDB                                   | `true`    |
| `redis.enabled`                         | Set to false to disable Redis                                   | `true`    |
| `kafka.enabled`                           | Set to false to disable Kafka&Zookeeper                           | `true`    |
| `deployment_sdui_cl.replicaCount`         | Numnber of instances of Closed Loop UI                                | `1`       |
| `statefulset_sdcl.replicaCount`           | Number of nodes processing  assurance and non-assurance requests        | `2`       |
| `statefulset_sdcl.replicaCount_asr_only`  | Number of nodes processing only assurance requests       | `0`       |
| `deployment_sdsnmp.replicaCount`          | Set to 0 to disable SNMP Adapter                                  | `1`       |
| `sdimage.repository`                      | Set to point to the Docker registry where SD images are kept      | null      |
| `sdimage.version`                         | Set to version of SD image used during deployment                 | latest    |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [livenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check.

If you are using an external database, you need to adjust `SDCONF_activator_db_`-prefixed environment variables as appropriate for the [values.yaml](./chart/values.yaml), also you need to make sure that your database is ready to accept connections before deploying the helm chart.

**IMPORTANT** The [./chart/values.yaml](values.yaml) file defines the docker registry (`hub.docker.hpecorp.net/cms-sd`) for the used SD images. This shall be changed to point to the docker registry where your docker images are located. E.g.: (`- image: myrepository.com/cms-sd/sd-sp`)
If you need to mount your own Helm SD repository you can use the files contained in the [repo](./repo/) folder, it contains the [index.yaml](./repo/index.yaml) file with the URL of the compress tgz version of the Helm chart. You have to change this URL to point to your local Helm repo.

**NOTE** A guidance in the amount of Memory and Disk for the helm chart deployment is that it requires 4GB RAM and minimum 25GB free Disk space on the assigned K8s nodes running it. The amount of Memory of cause depends of other applications/pods running in same node.
In case K8s master and worker-node are in same host, like Minikube, then minimum 16GB RAM and 80GB Disk is required.

To validate if the deployed sd-cl applications is ready:

    helm ls --namespace=servicedirector

the following chart must show an status of DEPLOYED:

    NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    sd-helm     1               Mon Dec 16 17:36:44 2019        DEPLOYED        sd_helm_chart-3.1.2     3.1.2             servicedirector

When the SD-CL application is ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    Service Director UI:
    http://<cluster_ip>:32519/login             (Service Director UI for Closed Loop nodes)
    http://<cluster_ip>:32518/activator/        (Service Director native UI)

**NOTE** The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the Helm chart example execute the following command:

    helm uninstall sd-helm --namespace=servicedirector


## SD Provisioner Deployment

In order to install SD provisioner example using Helm, the SD Helm repos must be added using the following commands:

    helm repo add couchdb https://apache.github.io/couchdb-helm
    helm repo add sd-chart-repo https://raw.github.hpe.com/hpsd/sd-cloud/master/kubernetes/helm/sd-chart/repo/

Then the following command must be executed to install Service Director :

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimage.install_assurance=false,kafka.enabled=false,sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector

Where `<image-tag>` is the Service Director version you want to install, if this parameter is omitted then the latest image available is used by default.

The value `<repo>` is the Docker repo where Service Director image is stored, usually this value is "hub.docker.hpecorp.net/cms-sd" .If this parameter is not included then the local repo is used by default.

The [/repo](./repo) folder contains the Helm chart that deploys the following:

- `sd-sp`:              HPE SD Provisioning node - [sd-sp](../../docker/images/sd-sp)
- `sd-ui`:              UOC-based UI connected to HPE Service Director - [sd-ui](../../docker/images/sd-ui)
- `sd-helm-couchdb`:    CouchDB database
- `redis-master`:    Redis database

Some of the containers won't deploy in you cluster depending on the parameters chosen during helm chart startup.

The following services are also exposed to external ports in the k8s cluster:

- `sd-sp` -> `32517`:   Service Director native UI
- `sd-ui` -> `32519`:   Unified OSS Console (UOC) for Service Director

The following table lists common configurable parameters of the chart and their default values. See [values.yaml](./chart/values.yaml) for all available options.

| Parameter                         | Description                                                   | Default   |
|---------------------------------------|-----------------------------------------------------------|-----------|
| `sdimage.install_assurance`       | Set to false to disable Closed Loop                           | `true`    |
| `couchdb.enabled`                 | Set to false to disable CouchDB                               | `true`    |
| `redis.enabled`                 | Set to false to disable Redis                               | `true`    |
| `kafka.enabled`                   | Set to false to disable Kafka&Zookeeper                       | `false`   |
| `statefulset_sdsp.replicaCount`   | Set to 0 to disable Service provisioner nodes                 | `1`       |
| `deployment_sdui.replicaCount`    | Set to 0 to disable Service director UI                       | `1`       |
| `deployment_sdsnmp.replicaCount`  | Set to 0 to disable SNMP Adapter                              | `1`       |
| `sdimage.repository`              | Set to point to the Docker registry where SD images are kept  | null      |
| `sdimage.version`                 | Set to version of SD image used during deployment             | latest    |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [livenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check.

If you are using an external database, you need to adjust `SDCONF_activator_db_`-prefixed environment variables as appropriate for the [values.yaml](./chart/values.yaml), also you need to make sure that your database is ready to accept connections before deploying the helm chart.

**IMPORTANT** The [./chart/values.yaml](values.yaml) file defines the docker registry (`hub.docker.hpecorp.net/cms-sd`) for the used images. This shall be changed to point to the docker registry where your docker images are located. E.g.: (`- image: myrepository.com/cms-sd/sd-sp`)
If you need to mount your own Helm SD repository you can use the files contained in the [repo](./repo/) folder, it contains the [index.yaml](./repo/index.yaml) file with the URL of the compress tgz version of the Helm chart. You have to change this URL to point to your local Helm repo.


**NOTE** A guidance in the amount of Memory and Disk for the helm chart deployment is that it requires 4GB RAM and minimum 25GB free Disk space on the assigned K8s nodes running it. The amount of Memory of cause depends of other applications/pods running in same node.

In case K8s master and worker-node are in same host, like Minikube, then minimum 16GB RAM and 80GB Disk is required.

To validate if the deployed sd-sp applications is ready:

    helm ls --namespace=servicedirector

the following chart must show an status of DEPLOYED:

    NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    sd-helm     1               Mon Dec 16 17:36:44 2019        DEPLOYED        sd_helm_chart-3.1.2     3.1.2           servicedirector

When the SD application is ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    Service Director UI:
    http://<cluster_ip>:32519/login             (Service Director UI)
    http://<cluster_ip>:32517/activator/        (Service Director provisioning native UI)


**NOTE** The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the Helm chart example execute the following command:

    helm uninstall sd-helm --namespace=servicedirector


## Service Activator High Availability Scenarios

### How to scale up/down provisioner nodes

The default provisioner replicas is 1, if you want scale up/down the provisioner nodes you can use the following command:

    kubectl scale statefulset sd-sp --replicas=x --namespace servicedirector

where x is the number of replicas you want to run


### How to scale up/down closed loop nodes

The Closed Loop example deploys three different provisioner pods, each one with a different purpose:

 `sd-cl-asr-only`:  HPE SD Closed Loop nodes, processing only assurance requests
 `sd-sp`:           HPE SD nodes,processing only non-assurance requests
 `sd-cl`:           HPE SD Closed Loop nodes, processing all type of requests

The default sd-cl-asr-only pod replicas is 1, if you want scale up/down the provisioner nodes you can use the following command:

    kubectl scale statefulset sd-cl-asr-only --replicas=x --namespace servicedirector

The default sd-cl pod replicas is 1, if you want scale up/down the provisioner nodes you can use the following command:

    kubectl scale statefulset sd-cl --replicas=x --namespace servicedirector

The default sd-sp pod replicas is 1, if you want scale up/down the provisioner nodes you can use the following command:

    kubectl scale statefulset sd-sp --replicas=x --namespace servicedirector

where x is the number of replicas you want to run


### How to scale up/down closed loop UI nodes

The default provisioner replicas is 1, if you want scale up/down the provisioner nodes you can use the following command:

    kubectl scale deployment sd-cl-ui --replicas=x --namespace servicedirector

where x is the number of replicas you want to run


### How to scale up/down provisioner UI nodes

The default provisioner replicas is 1, if you want scale up/down the provisioner nodes you can use the following command:

    kubectl scale deployment sd-ui --replicas=x --namespace servicedirector

where x is the number of replicas you want to run


## How to enable metrics and display them in Prometheus and Grafana

Prometheus and Grafana make it extremely easy to monitor just about any metric in your Kubernetes cluster, they can be deployed alongside "exporters" to expose cluster-level Kubernetes object metrics as well as machine-level metrics like CPU and memory usage.

This extra deployment can be activated during the helm chart execution using the following parameter:

    prometheus.enabled=true

Two dashboards are preloaded in Grafana in order to display information about the performance of SD pods in the cluster and Service Activator's metrics.

Before deploying Prometheus a namespace with the name "monitoring" must be created. In order to generate it, run

    kubectl create namespace monitoring
    
and this repo must be added using the following command:

    helm repo add bitnami https://charts.bitnami.com/bitnami    

You can find more information about how to run the example and how to connect to Grafana and Prometheus [here](../../examples/prometheus/)


## How to display SD logs and analyze them in Elasticsearch and Kibana

The ELK Stack helps by providing us with a powerful platform that collects and processes data from multiple SD logs, stores logs in one centralized data store that can scale as data grows, and provides a set of tools to analyze those logs.

This extra deployment can be activated during the helm chart execution using the following parameter:

    elk.enabled=true

Several Kibana indexes are preloaded in Kibana in order to display logs of Service Activator's activity.

Before deploying ELK a namespace with the name "monitoring" must be created. In order to generate it, run

    kubectl create namespace monitoring
    
and this repo must be added using the following command:

    helm repo add bitnami https://charts.bitnami.com/bitnami     

You can find more information about how to run the example and how to connect to ELK [here](../../examples/elk/)

## How to enable persistent volume in kafka, zookeeper, redis and couchdb

Redis, kafka/zookeeper and couchdb come with data persistance disable by default, in order to enable a persistent volume for some of them you have to start the helm chart with the following parameters:

    kafka.persistence.enabled=true
    kafka.zookeeper.persistence.enabled=true
    couchdb.persistentVolume.enabled=true
    redis.master.persistence.enabled=true

Therfore the following command must be executed to install Service Director (Closed Loop example):

    helm install sd-helm sd-chart-repo/sd_helm_chart --set kafka.persistence.enabled=true,kafka.zookeeper.persistence.enabled=true,couchdb.persistentVolume.enabled=true,redis.master.persistence.enabled=true,sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector

Previously to this step you need to generate persistent volumes in Kubernetes

Kafka, Zookeeper, Redis and CouchDB allow you to store its data on persistent storage, in that case a persistent volume must be created. This example only will explain how to create hostPath PersistentVolumes. Kubernetes supports hostPath for development and testing on a single-node cluster but in a production cluster, you would not use hostPath.

To use a local volume, the administrator must create the directories in which the volume will reside and ensure that the permissions on the directory allow write access. As an example you can use the following commands to set up the directories:

    mkdir /data/kafka
    mkdir /data/zookeeper
    mkdir /data/couchdb
    mkdir /data/redis

    chmod 777 /data/kafka
    chmod 777 /data/zookeeper
    chmod 777 /data/couchdb
    chmod 777 /data/redis

Where "/data/xxxx" is the full path to the folders in which the volumes will reside. If you want to use a different folder you have to modify the file [pv.yaml](./pv.yaml)

**NOTE** If you are using Minikube you have to add "storageClassName: standard" after the "spec:" line to the file [pv.yaml](./pv.yaml)

Then you have to generate some persistent volumes pointing to the folders created. As an example we provide the file [pv.yaml](./pv.yaml), using this file you can create the persistent volumes running:

    kubectl create -f pv.yaml

If you are using a kubernetes cluster with more than one node you cannot use a local storage and the example must be changed accordingly.

**NOTE**  In order to persist data with Redis you must also provide an existing PersistentVolumeClaim and its associated parameters,  you can find more info [here](https://github.com/bitnami/charts/tree/master/bitnami/redis/)



## Deleting Helm releases when persistent volumes are enable for kafka, zookeeper, redis or couchdb

Deleting the Helm release does not delete the persistent volume claims (PVC) that were created by the dependencies packages in the SD Helm chart. This behavior allows you to deploy the chart again with the same release name and keep your kafka, zookeeper and couchdb data. However, if you want to erase everything, you must delete the persistent volume claims manually. In order to delete every PVC you must issue the following commands:

    kubectl delete pvc data-kafka-service-0
    kubectl delete pvc data-zookeeper-service-0
    kubectl delete pvc database-storage-sd-helm-couchdb-0

**NOTE**  In order to persist data with Redis you must also provide an existing PersistentVolumeClaim and its associated parameters, deleting the PVC depends on the name previously given to the PVC, you can find more info [here](https://github.com/bitnami/charts/tree/master/bitnami/redis/)

Once the PVCs are deleted you can also delete the Persistent Volumes created using the following command:

    kubectl delete -f pv.yaml
