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

**NOTE**: If you are not using the K8S [postgres-db](../../examples/postgres-db) deployment, then you need to modify the [values.yaml](./chart/values.yaml) database related environments to point to the used database.

The following databases are available:

- Follow the deployment as described in [postgres-db](../../examples/postgres-db) directory.
- Follow the deployment as described in [enterprise-db](../../examples/enterprise-db) directory.
- Follow the deployment as described in [oracle-db](../../examples/oracle-db) directory.

**NOTE**: For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).


### 2. Namespace

Before deploying Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run

    kubectl create namespace servicedirector


## Using a Service Director license

By default, a 30-day Instant On license will be used. If you have a license file, you can supply it by creating a secret and bind-mounting it at `/license`, like this:

    kubectl create secret generic sd-license-secret --from-file=license=<license-file> -n servicedirector

Where `<license-file>` is the path to your Service Director license file.

Specify `licenseEnabled` parameter using the `--set key=value[,key=value]` argument to `helm install`.


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
| `sdimage.env.SDCONF_activator_db_vendor`  | Vendor or type of the database server used by HPE Service Activator. Supported values are Oracle, EnterpriseDB and PostgreSQL | PostgreSQL |
| `sdimage.env.SDCONF_activator_db_hostname`| Hostname of the database server used by HPE Service Activator. If you are not using a K8S deployment, then you need to point to the used database | postgres-nodeport |
| `sdimage.env.SDCONF_activator_db_instance`| Instance name for the database server used by HPE Service Activator   | sa |
| `sdimage.env.SDCONF_activator_db_user`    | Database username for HPE Service Activator to use                    | sa |
| `sdimage.env.SDCONF_activator_db_password`| Password for the HPE Service Activator database user                  | secret |
| `licenseEnabled`                          | Set true to use a license file                                        | `false` |


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
| `licenseEnabled`                          | Set true to use a license file                        | `false`   |

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

When Prometheus is enabled the Service Director pod will include a sidecar container called grok-exporter that exposes pod metrics to Prometheus, the image of Grok-exporter could be generated and deployed manually, as described [here](../../examples/prometheus/README.md#2.-deploy-sd-provisioning-+-grok-exporter), on each K8S node or pulled from a Docker repository. Some extra parameters should be added to the helm chart execution if the image is not stored locally:

    prometheus.grokexporter_repository=xxxxx              Docker registry path, it is usually "hub.docker.hpecorp.net/cms-sd/". By default is null.
    prometheus.grokexporter_name=xxxxx                    Name of the grokexporter image, by default is "grok_exporter"
    prometheus.grokexporter_tag=xxxxx                     Image tag for grokexporter, by default is null

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

The following logs will be available to Elasticsearch and Kibana:

  - Wildfly server logs as wildfly-yyyy.mm.dd
  - Server log from UOC as uoc-yyyy.mm.dd
 -  Service Activator workflow manager logs as sa_mwfm-yyyy.mm.dd
  - HPE SA resource manager logs as sa_resmgr-yyyy.mm.dd
  
You can find more information about how to run the example and how to connect to ELK [here](../../examples/elk/)

## How to enable persistent volume in kafka, zookeeper, redis and couchdb

A persistent volume (PV) is a cluster resource that you can use to store data for a pod and it persists beyond the lifetime of that pod. The PV is backed by networked storage system such as  NFS.

Redis, kafka/zookeeper and couchdb come with data persistance disable by default, in order to enable a persistent volume for some of them you have to start the helm chart with the following parameters:

    kafka.persistence.enabled=true
    kafka.zookeeper.persistence.enabled=true
    couchdb.persistentVolume.enabled=true
    redis.master.persistence.enabled=true

Therefore the following command must be executed to install Service Director (Closed Loop example):

    helm install sd-helm sd-chart-repo/sd_helm_chart --set kafka.persistence.enabled=true,kafka.zookeeper.persistence.enabled=true,couchdb.persistentVolume.enabled=true,redis.master.persistence.enabled=true,sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector

Previously to this step some persistent volumes must be generated in the Kubernetes cluster. Some Kubernetes distributions as Minikube or MicroK8S create the PVs for you, therefore the stotage persitence needed for kafka, zookeeper, redis , couchdb or database pods are automatically handled. You can read more information [here](../../docs/PersistentVolumes.md#persistent-volumes-in-single-node-configurations)

If you have configured dynamic provisioning on your cluster, such that all storage claims are dynamically provisioned using a storage class, as it is described [here](../../docs/PersistentVolumes.md#persistent-volumes-in-multi-node-configurations) you can skip the following steps.

If don't you have dynamic provisioning on your cluster then you need to create it manually and a default storage class, as it is described [here](../../docs/PersistentVolumes.md#local-volumes-in-k8s-nodes)


## Deleting Helm releases when persistent volumes are enabled for kafka, zookeeper, redis or couchdb

Deleting the Helm release does not delete the persistent volume claims (PVC) that were created by the dependencies packages in the SD Helm chart. This behavior allows you to deploy the chart again with the same release name and keep your kafka, zookeeper and couchdb data. However, if you want to erase everything, you must delete the persistent volume claims manually. In order to delete every PVC you must issue the following commands:

    kubectl delete pvc data-kafka-service-0
    kubectl delete pvc data-zookeeper-service-0
    kubectl delete pvc data-redis-master-0
    kubectl delete pvc database-storage-sd-helm-couchdb-0



## Ingress activation

Ingress is a Kubernetes-native way to implement the virtual hosting pattern, a mechanism to host many HTTP sites on a single IP address. Typically, you use an Ingress for decoding and directing incoming connections to the right Kubernetes service's app. Ingress can be setup in Service Director deployment in order to include one or several hosts names to target the native  UI and UOC UI.

If you have an Ingress controller already configured in your cluster, this extra deployment can be activated during the helm chart execution using the following parameter:

    ingress.enabled=true

The following table lists common configurable parameters of the chart and their default values. See [values.yaml](./chart/values.yaml) for all available options.

| Parameter                         | Description                                                   | Default   |
|---------------------------------------|-----------------------------------------------------------|-----------|
| `ingress.enabled` 	  | Enable ingress controller resource 	    | false    |
| `ingress.annotations` 	  | Ingress annotations done as key:value pairs,  see [annotations](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.mdl)  for a full list of possible ingress annotations.    | 	[]    |
| `ingress.hosts` 	  | The value ingress.host will contain the list of hostnames to be covered with this ingress record, these hostnames must be previously setup in your DNS system. The value is an array in case more than one hosts are needed. The following parameters are for the first host defined in your Ingress  | 	array   |
| `ingress.hosts[0].name` 	  | Hostname to your service director installation     | 	null    |
| `ingress.hosts[0].sdenabled` 	  | Set to true in order to enable a Service Director native UI path on the ingress record. Each sdenabled host will map the Service Director native UI requests to the /sd path.   | true    |
| `ingress.hosts[0].sduienabled` 	  | Set to true in order to enable a Service Director Unified OSS Console (UOC) path on the ingress record. Each sduienabled host will map the Service Director UOC UI requests to the /sdui path.   | true    |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

The following command is an example of an installation of Service Director with Ingress enabled:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set ingress.enabled=true,,ingress.hosts[0].name=sd.native.ui.com,ingress.hosts[0].sdenabled=true,ingress.hosts[0].sduienabled=false,ingress.hosts[1].name=sd.uoc.ui.com,ingress.hosts[1].sdenabled=false,ingress.hosts[1].sduienabled=true --namespace=servicedirector

The ingress configuration will setup two different host, one for Service Director native UI at:

    http://sd.native.ui.com/sd

and a Service Director Unified OSS Console (UOC) at:

    http://sd.uoc.ui.com/sdui


Another example of an installation of Service Director with Ingress enabled, with a single host with no name, using your cluster IP address:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set ingress.enabled=true --namespace=servicedirector

The ingress configuration will setup two different host, one for Service Director native UI at:

    http://xxx.xxx.xxx.xxx/sd

and a Service Director Unified OSS Console (UOC) at:

    http://xxx.xxx.xxx.xxx/sdui

where xxx.xxx.xxx.xxx is your cluster IP address.    

**NOTE**: As a guidance, we provide an example of how to deploy a NGINX Ingress:

In a bare metal Kubernetes cluster:

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml
    
If you want to use a Helm chart:

    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm install nginxingress ingress-nginx/ingress-nginx   
    
To enable the NGINX Ingress controller in minikube, run the following command:    
     
     minikube addons enable ingress
     
     
    


