# Service Director Helm chart Deployment Scenario
This folder defines a Helm chart and repo for all deployment scenarios of Service Director as service provisioner, Closed Loop or high availability. Deployment for Closed Loop nodes must include kubernetes cluster with, Apache Kafka, a SNMP Adapter and a Service Director UI as well. Deployment of Service Director as service provisioner nodes must include kubernetes cluster with Service Director UI.

The subfolder [/repo](../repo/) contains all the files of a Helm chart repository, that houses an [index.yaml](../repo/index.yaml) file and the packaged charts.

The subfolder [/chart](./sd-helm-chart) contains the files of the Helm chart, with the following files:

- `values-production.yaml`: provides the data passed into the chart (for production environments)
- `values.yaml`: provides the data passed into the chart (for testing environments)
- `Chart.yaml`: it contains the chart's metainformation
- `requirements.yaml`: lists the dependencies that your chart needs
- `requirements.lock`: lists the exact versions of dependencies
- `/templates/`: SD deployment files
- `/templates/ELK/`: support files for the ELK example
- `/templates/prometheus/`: support files for the Prometheus example
- `/templates/redis/`: support files for the Redis deployment
- `/charts/`: additional helm charts, needed as a dependency

As prerequisites for this deployment a database, a namespace and two persistent volumes are required.


## Prerequisites

### 1. Deploy database
**If you have already deployed a database, you can skip this step!**

For this example, we bring up an instance of the `postgres` image in a K8S Pod, which is basically a clean PostgreSQL 11 image with a `sa` user ready for Service Director installation.

**NOTE**: If you are not using the K8S [postgres-db](../../templates/postgres-db) deployment, then you need to modify the [testing values](./sd-helm-chart/values.yaml) or [production values](./sd-helm-chart/values-production.yaml). They contain some database related environments and point to the installed database. Those values can be added to the deployment using the "-f" parameter in the "helm install" command.

The following databases are available:

- Follow the deployment as described in [postgres-db](/kubernetes/templates/postgres-db) directory.
- Follow the deployment as described in [enterprise-db](/kubernetes/templates/enterprise-db) directory.
- Follow the deployment as described in [oracle-db](/kubernetes/templates/oracle-db) directory.

**NOTE**: For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).


### 2. Namespace
Before deploying Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run

    kubectl create namespace servicedirector


### 3. Resources in testing environments
Minimum requirements, for cpu and memory, are set by default in SD deployed pods. We recommend Kubernetes worker nodes with at least 8Gb and 6 cpus in order to allow SD pods starting without any problem, you know if some SD pod needs more resources when it is scheduled and you get errors as "FailedScheduling ... Insufficient cpu."

The default values for the resources are set to achieve a standard performance but they can be increased according to your needs. These default values can be too high in case you are using some testing environments as Minikube and must be changed accordingly.

You can find more information about tuning SD Hem chart resource parameters in the [following](../../docs/Resources.md) link.

The sd-ui pod needs a CouchDB instance in order to store session's data and work properly, this DB information must persist in the case of CoachDB pod restarts. Therefore a persistent storage would be used via a PVC object that CouchDB pod provides. The following parameters are available in the Helm chart during the installation of SD:

- `couchdb.persistentVolume.storageClass`: name of the storageClass that will provide the storage, if parameter is omitted the PVs available in the storageClass by default will be used.
- `couchdb.persistentVolume.size`: the size of the persistent volume to attach, 10Gi by default. Check your SD installation manual for the recommended size.

HPE Service Director Closed Loop relies on Apache Kafka as event collection framework. It creates a pod for Kafka and one pod for Zookeeper ready to be used for HPE Service Director as recommended.

### 4. Resources in production environments
Minimum requirements, for cpu and memory, are set by default in SD deployed pods. We recommend to adjust your K8S production cluster using this [guide](../../docs/production%20deployment%20guidance.md) 

The default values for the resources are set to achieve a standard performance but they can be increased according to your needs.

You can find more information about tuning SD Hem chart resource parameters in the [following](/kubernetes/docs/Resources.md) link.

Persistent storage is activated in all SD pods that require it by means of a storageclass, the Helm chart values file contain some [values](./sd-helm-chart/values-production.yaml) where the storageClass can be modified.

The sd-ui pod needs a CouchDB instance in order to store session's data and work properly, this DB information must persist in the case of CoachDB pod restarts. Therefore a persistent storage would be used via a storageclass. A CouchDB cluster is created to be used for HPE Service Director as recommended. The installation creates by default there CoachDB pods, they are configured to run in different worker nodes to better tolerate node failures.

HPE Service Director UI relies on Redis as event collection framework. A Redis cluster is created to be used for HPE Service Director as recommended. The installation creates by default there Redis pods working as a master and two slaves. They are configured to run in different worker nodes to better tolerate node failures.

HPE Service Director Closed Loop relies on Apache Kafka as event collection framework. A Kafka and Zookeeper cluster is created to be used for HPE Service Director as recommended. The installation creates by default three pods for Kafka and another three for Zookeeper, they are configured to run in different worker nodes to better tolerate node failures.

To better tolerate K8S node failures it is recommended to apply some affinty/antiaffinity policies to your Provisioning and CLosed Loop pods. The parameter sdimage.affinity is included in the Helm chart and it can  be used to define the policy you want to apply.

## Deploying Service Director
In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [LivenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check.

If you are using an external database, you need to adjust `SDCONF_activator_db_`-prefixed environment variables as appropriate for the [test values](./chart/values.yaml) or [production values](./sd-helm-chart/values-production.yaml), also you need to make sure that your database is ready to accept connections before deploying the helm chart.

**IMPORTANT** The [values.yaml](./sd-helm-chart/values.yaml) file defines the docker registry (`hub.docker.hpecorp.net/cms-sd`) for the used SD images. This shall be changed to point to the docker registry where your docker images are located. E.g.: (`- image: myrepository.com/cms-sd/sd-sp`)
If you need to mount your own Helm SD repository you can use the files contained in the [repo](./repo/) folder, it contains the [index.yaml](./repo/index.yaml) file with the URL of the compress tgz version of the Helm chart. You have to change this URL to point to your local Helm repo.

**NOTE**: A guidance in the amount of Memory and Disk for the helm chart deployment is that it requires 4GB RAM and minimum 25GB free Disk space on the assigned K8s nodes running it. The amount of Memory of course depends of other applications/pods running in same node.
In case K8s master and worker-node are in same host, like Minikube, then minimum 16GB RAM and 80GB Disk is required.

In case K8s master and worker-node are in same host, like Minikube, then minimum 16GB RAM and 80GB Disk is required.


### Using a Service Director license
By default, a 30-day Instant On license will be used. If you have a license file, you can supply it by creating a secret and bind-mounting it at `/license`, like this:

    kubectl create secret generic sd-license-secret --from-file=license=<license-file> -n servicedirector

Where `<license-file>` is the path to your Service Director license file.

Specify `licenseEnabled` parameter using the `--set key=value[,key=value]` argument to `helm install`.


### SD Closed Loop Deployment
In order to install SD Closed Loop example using Helm, the SD Helm repo must be added using the following command:

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add couchdb https://apache.github.io/couchdb-helm
    helm repo add sd-chart-repo https://raw.githubusercontent.com/HewlettPackard/hpe-sd-cloud/master/kubernetes/helm/repo/ 

The following command must be executed to install Service Director in a test environment:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector
    
The following command must be executed to install Service Director in a production environment:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector -f values-production.yaml
    
Where `<image-tag>` is the Service Director version you want to install, if this parameter is omitted then the latest image available is used by default.

The value `<repo>` is the Docker repo where Service Director image is stored, usually this value is "hub.docker.hpecorp.net/cms-sd/". If this parameter is not included then the local repo is used by default.

You can find additional information about production environments [here](../../docs/production deployment guidance.md) 

The Kubernetes cluster now contains the following pods:

- `sd-cl`: HPE SD Closed Loop nodes, processing assurance and non-assurance requests - [sd-sp](/docker/images/sd-sp)
- `sd-ui`: UOC-based UI connected to HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-snmp-adapter`: SD Closed Loop SNMP Adapter - [sd-sp](/docker/images/sd-cl-adapter-snmp)
- `kafka-service`: Kafka service
- `zookeeper-service`: Zookeeper service
- `sd-helm-couchdb`: CouchDB database
- `redis-master`: Redis database

Some of the containers won't deploy in your cluster depending on the parameters chosen during helm chart startup.

The following services are also exposed to external ports in the k8s cluster:

- `sd-cl` -> `32518`: Service Director Closed Loop node native UI
- `sd-cl-ui` -> `32519`: Unified OSS Console (UOC) for Service Director
- `sd-snmp-adapter` -> `32162`: Closed Loop SNMP Adapter Service Director

To validate if the deployed sd-cl applications is ready:

    helm ls --namespace=servicedirector

the following chart must show an status of DEPLOYED:

    NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    sd-helm     1               Mon Dec 16 17:36:44 2019        DEPLOYED        sd_helm_chart-3.1.2     3.1.2             servicedirector

When the SD-CL application is ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    Service Director UI:
    http://<cluster_ip>:32519/login             (Service Director UI for Closed Loop nodes)
    http://<cluster_ip>:32518/activator/        (Service Director native UI)

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the Helm chart example execute the following command:

    helm uninstall sd-helm --namespace=servicedirector


### SD Provisioner Deployment
In order to install SD provisioner example using Helm, the SD Helm repos must be added using the following commands:

    helm repo add couchdb https://apache.github.io/couchdb-helm
    helm repo add sd-chart-repo https://raw.githubusercontent.com/HewlettPackard/hpe-sd-cloud/master/kubernetes/helm/repo/ 

The following command must be executed to install Service Director :

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimage.install_assurance=false,sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector

The following command must be executed to install Service Director in a production environment:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimage.install_assurance=false,sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector -f values-production,yaml

Where `<image-tag>` is the Service Director version you want to install, if this parameter is omitted then the latest image available is used by default.

The value `<repo>` is the Docker repo where Service Director image is stored, usually this value is "hub.docker.hpecorp.net/cms-sd/" .If this parameter is not included then the local repo is used by default.

You can find additional information about production environments [here](../../docs/production deployment guidance.md) 

The [/repo](../repo) folder contains the Helm chart that deploys the following:

- `sd-sp`: HPE SD Provisioning node - [sd-sp](/docker/images/sd-sp)
- `sd-ui`: UOC-based UI connected to HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-helm-couchdb`: CouchDB database
- `redis-master`: Redis database

Some of the containers won't deploy in you cluster depending on the parameters chosen during helm chart startup.

The following services are also exposed to external ports in the k8s cluster:

- `sd-sp` -> `32517`: Service Director native UI
- `sd-ui` -> `32519`: Unified OSS Console (UOC) for Service Director

To validate if the deployed sd-sp applications is ready:

    helm ls --namespace=servicedirector

the following chart must show an status of DEPLOYED:

    NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    sd-helm     1               Mon Dec 16 17:36:44 2019        DEPLOYED        sd_helm_chart-3.1.2     3.1.2           servicedirector

When the SD application is ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    Service Director UI:
    http://<cluster_ip>:32519/login             (Service Director UI)
    http://<cluster_ip>:32517/activator/        (Service Director provisioning native UI)


**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the Helm chart example execute the following command:

    helm uninstall sd-helm --namespace=servicedirector


### Customization
The following table lists common configurable parameters of the chart and their default values. See [values.yaml](./sd-helm-chart/values.yaml) for all available options.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

#### Common parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `sdimage.repository` | Set to point to the Docker registry where SD images are kept | local registry (if using another repository, remember to add "/" at the end, e.g. hub.docker.hpecorp.net/cms-sd/) |
| `sdimage.version` | Set to version of SD image used during deployment | latest |
| `sdimage.install_assurance` | Set to false to disable Closed Loop | `true` |
| `couchdb.enabled` | Set to false to disable CouchDB | `true` |
| `redis.enabled` | Set to false to disable Redis | `true` |
| `sdimage.env.SDCONF_activator_db_vendor` | Vendor or type of the database server used by HPE Service Activator. Supported values are Oracle, EnterpriseDB and PostgreSQL | PostgreSQL |
| `sdimage.env.SDCONF_activator_db_hostname`| Hostname of the database server used by HPE Service Activator. If you are not using a K8S deployment, then you need to point to the used database | postgres-nodeport |
| `sdimage.env.SDCONF_activator_db_instance`| Instance name for the database server used by HPE Service Activator | sa |
| `sdimage.env.SDCONF_activator_db_user` | Database username for HPE Service Activator to use | sa |
| `sdimage.env.SDCONF_activator_db_password`| Password for the HPE Service Activator database user | secret |
| `licenseEnabled` | Set true to use a license file | `false` |

##### ReplicaCount Parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `statefulset_sdsp.replicaCount` | Set to 0 to disable Service provisioner nodes | `1` |
| `statefulset_sdcl.replicaCount` | Number of nodes processing assurance and non-assurance requests | `2` |
| `statefulset_sdcl.replicaCount_asr_only` | Number of nodes processing only assurance requests | `0` |
| `statefulset_sdui.replicaCount` | Set to 0 to disable Service director UI | `1` |
| `statefulset_sdui_cl.replicaCount` | Numnber of instances of Closed Loop UI | `1` |
| `deployment_sdsnmp.replicaCount` | Set to 0 to disable SNMP Adapter | `1` |

#### Resources parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `sdui_image.memoryrequested`|  Amount of memory a cluster node needs to provide in order to start the UI container. | `300Mb` |
| `sdui_image.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the UI container. | `0.7` |
| `sdui_image.memorylimit` | Max. amount of memory a cluster node will provide to the UI container. No limit by default. | null |
| `sdui_image.cpulimit` | Max. amount of cpu a cluster node will provide to the UI container. No limit by default. | null |
| `sdui_image.filebeat.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the UI filebeat container in the ELK example. | `100Mb` |
| `sdui_image.filebeat.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the UI filebeat container in the ELK example. | `0.1` |
| `sdui_image.filebeat.memorylimit` | Max. amount of memory a cluster node will provide to the UI filebeat container in the ELK example. No limit by default. | null |
| `sdui_image.filebeat.cpulimit` | Max. amount of memory a cluster node will provide to the UI filebeat container in the ELK example. No limit by default. | null |
| `deployment_sdsnmp.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the SNMP adapter container. | `150Mb` |
| `deployment_sdsnmp.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the SNMP adapter container. | `0.1` |
| `deployment_sdsnmp.memorylimit` | Max. amount of memory a cluster node will provide to the SNMP adapter container. No limit by default. | null |
| `deployment_sdsnmp.cpulimit` | Max. amount of cpu a cluster node will provide to the SNMP adapter container. No limit by default. | null |


#### Image resources parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `sdimage.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Closed Loop or Provisioner container. | `1Gb` |
| `sdimage.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Closed Loop or Provisioner container. | `3` |
| `sdimage.memorylimit` | Max. amount of memory a cluster node will provide to the Closed Loop or Provisioner container. No limit by default. | null |
| `sdimage.cpulimit` | Max. amount of cpu a cluster node will provide to the Closed Loop or Provisioner container. No limit by default. | null |
| `sdimage.filebeat.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the CL-SP filebeat container in the ELK example. | `10Mb` |
| `sdimage.filebeat.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the CL-SP filebeat container in the ELK example. | `0.1` |
| `sdimage.filebeat.memorylimit` | Max. amount of memory a cluster node will provide to the CL-SP filebeat container in the ELK example. No limit by default. | null |
| `sdimage.filebeat.cpulimit` | Max. amount of memory a cluster node will provide to the CL-SP filebeat container in the ELK example. No limit by default. | null |
| `sdimage.grokexporter.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the grokexporter container in the Prometheus example. | `100Mb` |
| `sdimage.grokexporter.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the grokexporter container in the Prometheus example. | `0.1` |
| `sdimage.grokexporter.memorylimit` | Max. amount of memory a cluster node will provide to the grokexporter container in the Prometheus example. No limit by default. | null |
| `sdimage.grokexporter.cpulimit` | Max. amount of memory a cluster node will provide to the grokexporter container in the Prometheus example. No limit by default. | null |


#### Prometheus resources parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `prometheus.grafana.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Grafana container in the Prometheus example | `100Mb` |
| `prometheus.grafana.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Grafana container in the Prometheus example. | `0.2` |
| `prometheus.grafana.memorylimit` | Max. amount of memory a cluster node will provide to the Grafana container in the Prometheus example. No limit by default. | null |
| `prometheus.grafana.cpulimit` | Max. amount of cpu a cluster node will provide to the Grafana container in the Prometheus example. No limit by default. | null |
| `prometheus.sqlexporter.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the sqlexporter container in the Prometheus example | `50Mb` |
| `prometheus.sqlexporter.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the sqlexporter container in the Prometheus example. | `0.1` |
| `prometheus.sqlexporter.memorylimit` | Max. amount of memory a cluster node will provide to the sqlexporter container in the Prometheus example. No limit by default. | null |
| `prometheus.sqlexporter.cpulimit` | Max. amount of cpu a cluster node will provide to the sqlexporter container in the Prometheus example. No limit by default. | null |
| `prometheus.ksm.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the kube-state-metrics container in the Prometheus example  | `50Mb` |
| `prometheus.ksm.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the kube-state-metrics container in the Prometheus example. | `0.1` |
| `prometheus.ksm.memorylimit` | Max. amount of memory a cluster node will provide to the kube-state-metrics container in the Prometheus example. No limit by default. | null |
| `prometheus.ksm.cpulimit` | Max. amount of cpu a cluster node will provide to the kube-state-metrics container in the Prometheus example. No limit by default. | null |


#### ELK resources parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `elk.elastic.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Elasticsearch container in the ELK example. | `1.3Gb` |
| `elk.elastic.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Elasticsearch container in the ELK example. | `0.4` |
| `elk.elastic.memorylimit` | Max. amount of memory a cluster node will provide to the Elasticsearch container in the ELK example. No limit by default. | null |
| `elk.elastic.cpulimit` | Max. amount of cpu a cluster node will provide to the Elasticsearch container in the ELK example. No limit by default. | null |
| `elk.kibana.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Kibana container in the ELK example. | `400Mb` |
| `elk.kibana.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Kibana container in the ELK example. | `0.3` |
| `elk.kibana.memorylimit` | Max. amount of memory a cluster node will provide to the Kibana container in the ELK example. No limit by default. | null |
| `elk.kibana.cpulimit` | Max. amount of cpu a cluster node will provide to the Kibana container in the ELK example. No limit by default. | null    |
| `elk.logstash.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Logstash container in the ELK example. | `350Mb` |
| `elk.logstash.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Logstash container in the ELK example. | `0.1` |
| `elk.logstash.memorylimit` | Max. amount of memory a cluster node will provide to the Logstash container in the ELK example. No limit by default. | null |
| `elk.logstash.cpulimit` | Max. amount of cpu a cluster node will provide to the Logstash container in the ELK example. No limit by default. | null |


## Service Director High Availability
When installing the SD helm chart, you can decide to increase the number of pods for the SD deployment. To do so, please adjust the number of the replica count parameters when you do the helm install or upgrade.

![SD-HA](/kubernetes/docs/images/SD-HA.png)

You can adjust the following replica counts for the pods in the Helm chart [ReplicaCount Parameters](#replicacount-parameters)

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

For a HA deployment of a Pod, each replicacount shall be set to atleast the value 2. E.g.:

    --set statefulset_sdsp.replicaCount=2,statefulset_sdui.replicaCount=2

K8s will ensure the number of replicas is always the desired state of the running pods in the Helm deployment.

Find more information here about [Scaling Best Practices](/kubernetes/docs/ScalingBestPractices.md).

## Enable metrics and display them in Prometheus and Grafana
Prometheus and Grafana make it extremely easy to monitor just about any metric in your Kubernetes cluster, they can be deployed alongside "exporters" to expose cluster-level Kubernetes object metrics as well as machine-level metrics like CPU and memory usage.

This extra deployment can be activated during the helm chart execution using the following parameter:

    prometheus.enabled=true

Two dashboards are preloaded in Grafana in order to display information about the performance of SD pods in the cluster and Service Activator's metrics.

Before deploying Prometheus a namespace with the name "monitoring" must be created. In order to generate it, run

    kubectl create namespace monitoring

and this repo must be added using the following command:

    helm repo add bitnami https://charts.bitnami.com/bitnami

When Prometheus is enabled the Service Director pod will include a sidecar container called grok-exporter that exposes pod metrics to Prometheus, the image of Grok-exporter could be generated and deployed manually, as described [here](/docker/examples/grokexporter/README.md), on each K8S node or pulled from a Docker repository. Some extra parameters should be added to the helm chart execution if the image is not stored locally:

    prometheus.grokexporter_repository=xxxxx        Docker registry path, it is usually "hub.docker.hpecorp.net/cms-sd/". By default is null.
    prometheus.grokexporter_name=xxxxx              Name of the grokexporter image, by default is "grok_exporter"
    prometheus.grokexporter_tag=xxxxx               Image tag for grokexporter, by default is null

You can find more information about how to run the example and how to connect to Grafana and Prometheus [here](/kubernetes/docs/alertmanager)

By default, Redis metrics are not included when enabling metrics. To enable them the following parameter needs to be added to the helm chart execution:

    redis.metrics.enabled=true

This will also preload a Redis example graph in Grafana.


## Display SD logs and analyze them in Elasticsearch and Kibana
The ELK Stack helps by providing us with a powerful platform that collects and processes data from multiple SD logs, stores logs in one centralized data store that can scale as data grows, and provides a set of tools to analyze those logs.

Filebeat data folder stores a registry of read status for all log files, so it doesn't send everything again to Logstash on a pod restart. This folder must be created in a persistent storage therefore created outside the container, on the Kubernetes nodes. By default the folder is:

    mkdir /var/lib/filebeat-data
    chmod -R 777 /var/lib/filebeat-data

Be sure the folder has write permissions for the container to write on it. The path can be found under "volumes" in sd-filebeat.yaml

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
- Service Activator workflow manager logs as sa_mwfm-yyyy.mm.dd
- HPE SA resource manager logs as sa_resmgr-yyyy.mm.dd
- Redis messages redis-input-YYYY.MM.dd

Filebeat container collects the following SD log information and send it to Logstash pod:

- `SD container`: WildFly log using the following path - /opt/HP/jboss/standalone/log/
- `SD container`: Service Activator losg using the following path - /var/opt/OV/ServiceActivator/log/
- `SD container`: SNMP adapter log using the following path - /opt/sd-asr/adapter/log/
- `SD UI container`: UOC log using the following path - /var/opt//uoc2/logs

You can check if the SD logs indexes were created and stored in Elasticsearch using the Kibana web interface, you can find more information [here](../../docs/Kibana.md)

Raising SD alerts with ELK is optional in the SD helm chart and it is not activated by default, some additional setup must be done. You can find more information [here](../../docs/elastalert/README.md)


## Persistent Volumes

### How to enable Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB
A persistent volume (PV) is a cluster resource that you can use to store data for a pod and it persists beyond the lifetime of that pod. The PV is backed by networked storage system such as NFS.

Redis, Kafka/Zookeeper and CouchDB come with data persistance disable by default, in order to enable a persistent volume for some of them you have to start the helm chart with the following parameters:

    kafka.persistence.enabled=true
    kafka.zookeeper.persistence.enabled=true
    couchdb.persistentVolume.enabled=true
    redis.master.persistence.enabled=true

Therefore the following command must be executed to install Service Director (Closed Loop example):

    helm install sd-helm sd-chart-repo/sd_helm_chart --set kafka.persistence.enabled=true,kafka.zookeeper.persistence.enabled=true,couchdb.persistentVolume.enabled=true,redis.master.persistence.enabled=true,sdimage.repository=<repo>,sdimage.version=<image-tag> --namespace=servicedirector

Previously to this step some persistent volumes must be generated in the Kubernetes cluster. Some Kubernetes distributions as Minikube or MicroK8S create the PVs for you, therefore the stotage persitence needed for Kafka, Zookeeper, Redis , CouchDB or database pods are automatically handled. You can read more information [here](/kubernetes/docs/PersistentVolumes.md#persistent-volumes-in-single-node-configurations)

If you have configured dynamic provisioning on your cluster, such that all storage claims are dynamically provisioned using a storage class, as it is described [here](/kubernetes/docs/PersistentVolumes.md#persistent-volumes-in-multi-node-configurations) you can skip the following steps.

If don't you have dynamic provisioning on your cluster then you need to create it manually and a default storage class, as it is described [here](/kubernetes/docs/PersistentVolumes.md#local-volumes-in-k8s-nodes)

### How to delete Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB
Deleting the Helm release does not delete the persistent volume claims (PVC) that were created by the dependencies packages in the SD Helm chart. This behavior allows you to deploy the chart again with the same release name and keep your Kafka, Zookeeper and CouchDB data. However, if you want to erase everything, you must delete the persistent volume claims manually. In order to delete every PVC you must issue the following commands:

    kubectl delete pvc data-kafka-service-0
    kubectl delete pvc data-zookeeper-service-0
    kubectl delete pvc data-redis-master-0
    kubectl delete pvc database-storage-sd-helm-couchdb-0


## Ingress activation
Ingress is a Kubernetes-native way to implement the virtual hosting pattern, a mechanism to host many HTTP sites on a single IP address. Typically, you use an Ingress for decoding and directing incoming connections to the right Kubernetes service's app. Ingress can be setup in Service Director deployment in order to include one or several hosts names to target the native UI and UOC UI.

If you have an Ingress controller already configured in your cluster, this extra deployment can be activated during the helm chart execution using the following parameter:

    ingress.enabled=true

The following table lists common configurable parameters of the chart and their default values. See [values.yaml](./sd-helm-chart/values.yaml) for all available options.

| Parameter | Description | Default |
|-----|-----|-----|
| `ingress.enabled` | Enable ingress controller resource | false |
| `ingress.annotations` | Ingress annotations done as key:value pairs, see [annotations](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.mdl) for a full list of possible ingress annotations. | [] |
| `ingress.hosts` | The value ingress.host will contain the list of hostnames to be covered with this ingress record, these hostnames must be previously setup in your DNS system. The value is an array in case more than one hosts are needed. The following parameters are for the first host defined in your Ingress | array |
| `ingress.hosts[0].name` | Hostname to your service director installation | null |
| `ingress.hosts[0].sdenabled` | Set to true in order to enable a Service Director native UI path on the ingress record. Each sdenabled host will map the Service Director native UI requests to the /sd path. | true |
| `ingress.hosts[0].sduienabled` | Set to true in order to enable a Service Director Unified OSS Console (UOC) path on the ingress record. Each sduienabled host will map the Service Director UOC UI requests to the /sdui path. | true |

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
