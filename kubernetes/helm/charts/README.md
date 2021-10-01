# Service Director Helm chart Deployment

## Contents
   * [Service Director Helm chart Deployment](#service-director-helm-chart-deployment)
      * [Introduction](#introduction)
      * [Prerequisites](#prerequisites)
         * [1. Deploy database](#1-deploy-database)
         * [2. Namespace](#2-namespace)
         * [3. Resources](#3-resources)
            * [Resources in testing environments](#resources-in-testing-environments)
            * [Resources in production environments](#resources-in-production-environments)
         * [4. Kubernetes version](#4-kubernetes-version)
      * [Deploying Service Director](#deploying-service-director)
         * [Access to SD Docker images from public DTR](#access-to-sd-docker-images-from-public-dtr)
         * [Using a Service Director license](#using-a-service-director-license)
         * [Add Secure Shell (SSH) Key configuration for SD](#add-secure-shell-ssh-key-configuration-for-sd)
         * [Using Service Account](#using-service-account)
         * [Add Security Context configuration](#add-security-context-configuration)
         * [SD Closed Loop Deployment](#sd-closed-loop-deployment)
            * [Non-root deployment](#non-root-deployment)
         * [SD Provisioner Deployment](#sd-provisioner-deployment)
         * [Exposing services](#exposing-services)
            * [In testing environments](#in-testing-environments)
            * [In production environments](#in-production-environments)
         * [Customization](#customization)
            * [Global parameters](#global-parameters)
            * [Common parameters](#common-parameters)
            * [Service parameters](#service-parameters)
               * [ReplicaCount Parameters](#replicacount-parameters)
            * [Resources parameters](#resources-parameters)
            * [Image resources parameters](#image-resources-parameters)
            * [Prometheus resources parameters](#prometheus-resources-parameters)
            * [ELK resources parameters](#elk-resources-parameters)
            * [SD configuration parameters](#sd-configuration-parameters)
            * [Kafka and Zookeeper configuration parameters](#kafka-and-zookeeper-configuration-parameters)
            * [Add custom variables within a ConfigMap](#add-custom-variables-within-a-configmap)
            * [Labeling pods and services](#labeling-pods-and-services)
         * [Upgrade HPE Service Director Deployment](#upgrade-hpe-service-director-deployment)
         * [Uninstall HPE Service Director Deployment](#uninstall-hpe-service-director-deployment)
      * [Service Director High Availability](#service-director-high-availability)
      * [Enable metrics and display them in Prometheus and Grafana](#enable-metrics-and-display-them-in-prometheus-and-grafana)
         * [Additional metrics](#additional-metrics)
         * [Troubleshooting](#troubleshooting)
      * [Display SD logs and analyze them in Elasticsearch and Kibana](#display-sd-logs-and-analyze-them-in-elasticsearch-and-kibana)
        * [Configuring the log format](#configuring-the-log-format)
        * [Configuring Logstash pipeline](#configuring-logstash-pipeline)
      * [Persistent Volumes](#persistent-volumes)
         * [How to enable Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB](#how-to-enable-persistent-volumes-in-kafka-zookeeper-redis-and-couchdb)
         * [How to delete Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB](#how-to-delete-persistent-volumes-in-kafka-zookeeper-redis-and-couchdb)
      * [Ingress activation](#ingress-activation)
      * [Healthcheck pod for Service Director ](#healthcheck-pod-for-service-director)

## Introduction
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

## Prerequisites
As prerequisites for the Service Director Helm Chart deployment a database and a namespace is required.

### 1. Deploy database
**If you have already deployed a database, you can skip this step!**

For this example, we bring up an instance of the `postgres` image in a K8S Pod, which is basically a clean PostgreSQL 11 image with a `sa` user ready for Service Director installation.

The parameters that setup the DB connection can be found in values.yaml file or values-production.yaml , depending on the environment. The description of the parameters can be found [here](/kubernetes/helm/charts#common-parameters) , you can also read [this](/kubernetes/helm/charts#dbsecret) to create your own DB password.

**NOTE**: If you are not using the K8S [postgres-db](../../templates/postgres-db) deployment, then you need to modify the [testing values](./sd-helm-chart/values.yaml) or [production values](./sd-helm-chart/values-production.yaml). They contain some database related environments and point to the installed database. Those values can be added to the deployment using the "-f" parameter in the "helm install" command.

The following databases are available:

- Follow the deployment as described in [postgres-db](/kubernetes/templates/postgres-db) directory.
- Follow the deployment as described in [enterprise-db](/kubernetes/templates/enterprise-db) directory.
- Follow the deployment as described in [oracle-db](/kubernetes/templates/oracle-db) directory.

**NOTE**: For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).


### 2. Namespace
Before deploying Service Director a namespace with the name "sd" must be created. In order to generate the namespace, run

    kubectl create namespace sd

### 3. Resources
#### Resources in testing environments
Minimum requirements, for cpu and memory, are set by default in SD deployed pods. We recommend Kubernetes worker nodes with at least 8Gb and 6 CPUs in order to allow SD pods starting without any problem, you know if some SD pod needs more resources when it is scheduled and you get errors as "FailedScheduling ... Insufficient cpu."

The default values for the resources are set to achieve a minimum performance, 1Gb and 3 CPUs for SD provisioner and 0.5Gb and 1 CPU for SD UI, but they can be increased according to your needs. The default limit values, 3Gb and 5 CPUs for SD provisioner and 3Gb and 3 CPU for SD UI, can be too high in case you are using some testing environments as Minikube and must be changed accordingly.

You can find more information about tuning SD Helm chart resource parameters in the [Resources](../../docs/Resources.md) doc.

The sd-ui pod needs a CouchDB instance in order to store session's data and work properly, this DB information must persist in the case of CouchDB pod restarts. Therefore a persistent storage would be used via a PVC object that CouchDB pod provides. The following parameters are available in the Helm chart during the installation of SD:

- `couchdb.persistentVolume.storageClass`: name of the storageClass that will provide the storage, if parameter is omitted the PVs available in the storageClass by default will be used.
- `couchdb.persistentVolume.size`: the size of the persistent volume to attach, 10Gi by default. Check your SD installation manual for the recommended size.

HPE Service Director Closed Loop can be configured to use Apache Kafka as event collection framework. If it is enabled, it creates a pod for Kafka and one pod for Zookeeper ready to be used for HPE Service Director as recommended.

#### Resources in production environments
Minimum requirements, for cpu and memory, are set by default in SD deployed pods. We recommend to adjust your K8S production cluster using this [guide](../../docs/production%20deployment%20guidance.md)

The default values for the resources are set to achieve a minimum performance, 1Gb and 3 CPUs for SD provisioner and 0.5Gb and 1 CPU for SD UI, but they must be increased according to your needs. The default limit values are 3Gb and 5 CPUs for SD provisioner and 3Gb and 3 CPU for SD UI, but they should be increased according to your needs.

You can find more information about tuning SD Helm chart resource parameters in the [Resources](/kubernetes/docs/Resources.md) doc.

Persistent storage is activated in all SD pods that require it by means of a storageclass, the Helm chart values file contain some [values](./sd-helm-chart/values-production.yaml) where the storageClass can be modified.

The sd-ui pod needs a CouchDB instance in order to store session's data and work properly, this DB information must persist in the case of CouchDB pod restarts. Therefore a persistent storage would be used via a storageclass. A CouchDB cluster is created to be used for HPE Service Director as recommended. The installation creates by default there CouchDB pods, they are configured to run in different worker nodes to better tolerate node failures.

HPE Service Director UI relies on Redis as a notification system and session management framework. A Redis cluster is created to be used for HPE Service Director as recommended. The installation creates by default three Redis pods working as a master and two slaves. They are configured to run in different worker nodes to better tolerate node failures.

HPE Service Director Closed Loop can be configured to use Apache Kafka as event collection framework. If it is enabled, it creates a Kafka and Zookeeper cluster is created to be used for HPE Service Director as recommended. The installation creates by default three pods for Kafka and another three for Zookeeper, they are configured to run in different worker nodes to better tolerate node failures.

To better tolerate K8S node failures it is recommended to apply some affinty/antiaffinity policies to your Provisioning and Closed Loop pods. Some affinity parameters are already included in the Helm chart and they are used to spread the pod instances between the nodes of the K8S cluster, we recommend to review them and modify to comply with your affinty/antiaffinity policies .

| Parameter | Description | Default |
|-----|-----|-----|
| `kafka.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread kafka instances between the nodes of the K8S cluster  |
| `kafka.zookeeper.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread zookeeper instances between the nodes of the K8S cluster  |
| `couchdb.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread couchdb instances between the nodes of the K8S cluster  |
| `redis.master.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread redis master instances between the nodes of the K8S cluster  |
| `redis.slave.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread redis slave instances between the nodes of the K8S cluster  |
| `prometheus.grafana.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread grafana instances between the nodes of the K8S cluster  |
| `elk.elastik.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread elasticsearch instances between the nodes of the K8S cluster  |
| `sdimage.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread provisioner instances between the nodes of the K8S cluster  |
| `sdui_image.affinity` | Use it to add affinty/antiaffinity policies. | podAntiAffinity rule set to spread SD UI instances between the nodes of the K8S cluster  |




### 4. Kubernetes version

Kubernetes version 1.18.0 or later is supported, using an older version of Kubernetes is not supported.

**Note**: Using an older version of Kubernetes can make some SD components not to work as expected or even not able to deploy the Helm chart at all.

## Deploying Service Director
In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), [LivenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [StartupProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check.

If you are using an external database, you need to adjust `SDCONF_activator_db_`-prefixed environment variables as appropriate for the [test values](./chart/values.yaml) or [production values](./sd-helm-chart/values-production.yaml), also you need to make sure that your database is ready to accept connections before deploying the helm chart.

**IMPORTANT** The [values.yaml](./sd-helm-chart/values.yaml) file defines the docker registry (`hub.docker.hpecorp.net/cms-sd`) for the used SD images. This shall be changed to point to the docker registry where your docker images are located. E.g.: (`- image: myrepository.com/cms-sd/sd-sp`)
If you need to mount your own Helm SD repository you can use the files contained in the [repo](../repo/) folder, it contains the [index.yaml](../repo/index.yaml) file with the URL of the compress tgz version of the Helm chart. You have to change this URL to point to your local Helm repo.

**NOTE**: A guidance in the amount of Memory and Disk for the helm chart deployment is that it requires 4GB RAM and minimum 25GB free Disk space on the assigned K8s nodes running it. The amount of Memory of course depends of other applications/pods running in same node.

In case K8s master and worker-node are in same host, like Minikube, then minimum 16GB RAM and 80GB Disk is required.

### Access to SD Docker images from public DTR
It is possible to pull the SD Docker Images from the HPE public Docker Trusted Registry(DTR).  
It requires a HPE Passport account and an `access token` to retrieve the SD images from the Public HPE DTR. 
The access token will be delivered to the customer as part of the order fulfillment process. Once the customer has validated an order via the HPE Software Center portal, s/he will receive an email notification with details on the access token and instructions on how to retrieve images using the token:

    docker login -u <customer@company.com> hub.myenterpriselicense.hpe.com
    Password: <access token>
    Login succeeded 
    
After login, the SD docker images can now be pulled:

    docker pull hub.myenterpriselicense.hpe.com/r1l78aae/sd-sp[:tag]
    docker pull hub.myenterpriselicense.hpe.com/r1l78aae/sd-ui[:tag]
    docker pull hub.myenterpriselicense.hpe.com/r1l78aae/sd-cl-adapter-snmp[:tag]

Please consult the Release Notes in [releases](https://github.hpe.com/hpsd/sd-cloud/releases) to get more informtion about image signature validation and changes for each release.

### Using a Service Director license
By default, a 30-day Instant On license will be used. If you have a license file, you can supply it by creating a secret and bind-mounting it at `/license`, like this:

    kubectl create secret generic sd-license-secret --from-file=license=<license-file> --namespace sd

Where `<license-file>` is the path to your Service Director license file.

Specify `sdimage.licenseEnabled` parameter using the `--set key=value[,key=value]` argument to `helm install`.

### Add Secure Shell (SSH) Key configuration for SD
It is possible to set SD-SP up to connect to target devices using a single common ssh private/public key pair. To enable this a K8s secret must be generated.

By default, there is no SSH key pair provided. You need to create the required ssh key-pair using ssh-keygen and the private key must be provided to SD by creating a secret and bind-mounting it at `/ssh/identity`, like this:

     kubectl create secret generic ssh-identity --from-file=identity=<identity-file> --namespace sd

Where `<identity-file>` is the path to your SSH private key.

To enable the use of the ssh key by SD Helm chart specify the `sshEnabled` parameter by providing the `--set sdimage.sshEnabled=true` argument to `helm install`.

On target devices where this ssh connectivity is to be used the corresponding public key must be appended to the users `~/.ssh/authorized_keys` file. This is a manual step.

### Using Service Account
When using a private Docker Registry authentication is needed. To enable authentication a Service Account can be enabled. The steps to use the ServiceAccount feature are:

1. Create a Secret with the registry credentials
```
kubectl create secret docker-registry <secret-name> \
--docker-server=<repo> \
--docker-username=<username> --docker-password=<password> \
--docker-email=<email> \
--namespace sd
```

2. Set the `ServiceAccount` fields in your custom values file or in the --set parameters `helm install` command:
```
# values-file.yaml
serviceAccount:
  enabled: true
  create: true
  name: <service-account-name>
  imagePullSecrets:
  - name: <secret-name>
```

3. Run `helm install` command setting the images' repository and version:
```
helm install sd-helm sd-chart-repo/sd_helm_chart \
--set sdimages.registry=<repo>,\
sdimages.tag=<image-version> \
--values <values-file.yaml> \
--namespace sd
```

### Add Security Context configuration
A security Context defines privilege and access control settings for a Pod or Container. To specify security settings for a Pod you have to enable the `SecurityContext` in the values file. The securityContext root field is used as a global and default value, but you can also specify for each deployment its own Security Context also in the values file. Check this [table](#common-parameters) to see the description of the fields.

```
securityContext:
  enabled: false
  fsGroup: 1001
  runAsUser: 1001
```

### SD Closed Loop Deployment
In order to install SD Closed Loop example using Helm, the SD Helm repo must be added using the following command:

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add couchdb https://apache.github.io/couchdb-helm
    helm repo add sd-chart-repo https://raw.githubusercontent.com/HewlettPackard/hpe-sd-cloud/master/kubernetes/helm/repo/

The following command must be executed to install Service Director in a test environment:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<repo>,sdimages.tag=<image-tag> --namespace sd

The following command must be executed to install Service Director in a production environment:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<repo>,sdimages.tag=<image-tag> --namespace sd -f values-production.yaml

Where `<image-tag>` is the Service Director version you want to install, if this parameter is omitted then the latest image available is used by default.

The value `<repo>` is the Docker repo where Service Director image is stored, usually this value is "hub.docker.hpecorp.net/cms-sd/". If this parameter is not included then the local repo is used by default.

**NOTE**: The SNMP adapter needs Kafka to get Assurance data, and Kafka needs the SNMP adapter also to work properly in a Closed Loop deployment, so remember to always enable **both** of them. To do it, you can set the parameters `kafka.enabled=true` and `sdsnmp_adapter.enabled=true` or use **external** ones if you prefer.

You can find additional information about production environments [here](../../docs/production%20deployment%20guidance.md)

The Kubernetes cluster now contains the following pods:

- `sd-cl`: HPE SD Closed Loop nodes, processing assurance and non-assurance requests - [sd-sp](/docker/images/sd-sp)
- `sd-ui`: UOC-based UI connected to HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-helm-couchdb`: CouchDB database
- `redis-master`: Redis database

Some of the containers won't deploy in your cluster depending on the parameters chosen during helm chart startup.

The following services are also exposed to external ports in the k8s cluster:

- `sd-cl`: Service Director Closed Loop node native UI
- `sd-cl-ui`: Unified OSS Console (UOC) for Service Director

To validate if the deployed SD-CL application is ready:

    helm ls --namespace sd

the following chart must show an status of DEPLOYED:

    NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    sd-helm     1               Fri Oct  1 17:36:44 2021        DEPLOYED        sd_helm_chart-3.7.1     3.7.1             sd

When the SD-CL application is ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    Service Director UI:
    http://<cluster_ip>:<port>/login             (Service Director UI for Closed Loop nodes)
    http://<cluster_ip>:<port>/activator/        (Service Director native UI)

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

**NOTE**: The service `port` can be found running the `kubectl get services --namespace sd` command.

To delete the Helm chart example execute the following command:

    helm uninstall sd-helm --namespace sd

#### Non-root deployment
There is an important consideration to take into account about the SNMP adapter when deploying the SD Closed Loop as non-root: when running as a different user than root the adapter will not be able to listen on the default port 162, instead you will need to set `SDCONF_asr_adapters_manager_port` to a non-privileged port (e.g. 10162) and then if necessary, you can redirect to the public port 162 (-p 162:10162/udp). This is especially important to take into account when deploying to **OpenShift**.

### SD Provisioner Deployment
In order to install SD provisioner example using Helm, the SD Helm repos must be added using the following commands:

    helm repo add couchdb https://apache.github.io/couchdb-helm
    helm repo add sd-chart-repo https://raw.githubusercontent.com/HewlettPackard/hpe-sd-cloud/master/kubernetes/helm/repo/

The following command must be executed to install Service Director :

    helm install sd-helm sd-chart-repo/sd_helm_chart --set install_assurance=false,sdimages.registry=<repo>,sdimages.tag=<image-tag> --namespace sd

The following command must be executed to install Service Director in a production environment:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set install_assurance=false,sdimages.registry=<repo>,sdimages.tag=<image-tag> --namespace sd -f values-production.yaml

Where `<image-tag>` is the Service Director version you want to install, if this parameter is omitted then the latest image available is used by default.

The value `<repo>` is the Docker repo where Service Director image is stored, usually this value is "hub.docker.hpecorp.net/cms-sd/". If this parameter is not included then the local repo is used by default.

You can find additional information about production environments [here](../../docs/production%20deployment%20guidance.md)

The [/repo](../repo) folder contains the Helm chart that deploys the following:

- `sd-sp`: HPE SD Provisioning node - [sd-sp](/docker/images/sd-sp)
- `sd-ui`: UOC-based UI connected to HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-helm-couchdb`: CouchDB database
- `redis-master`: Redis database

Some of the containers won't deploy in you cluster depending on the parameters chosen during helm chart startup.

The following services are also exposed to external ports in the k8s cluster:

- `sd-sp`: Service Director native UI
- `sd-ui`: Unified OSS Console (UOC) for Service Director

To validate if the deployed sd-sp applications is ready:

    helm ls --namespace sd

the following chart must show an status of DEPLOYED:

    NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
    sd-helm     1               Fri Oct  1 17:36:44 2021        DEPLOYED        sd_helm_chart-3.7.1     3.7.1             sd

When the SD application is ready, then the deployed services (SD User Interfaces) are exposed on the following urls:

    Service Director UI:
    http://<cluster_ip>:<port>/login             (Service Director UI)
    http://<cluster_ip>:<port>/activator/        (Service Director provisioning native UI)

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

**NOTE**: The service `port` can be found running the `kubectl get services --namespace sd` command.

To delete the Helm chart example execute the following command:

    helm uninstall sd-helm --namespace sd

### Exposing services

#### In testing environments
By default, in testing environment some `NodePort` type services are exposed externally using a random port. You can check the value of the port of each service using the following command:

```
kubectl get pods --namespace sd
```

These services can be exposed externally on a fixed port specifying a port number on the `nodePort` parameter when you run the `helm install` command. You can see a complete service parameters list on [Service parameters](#service-parameters) section.

#### In production environments
In the production environment services are `CluterIP` type and they are not exposed externally by default.

### Customization
The following table lists common configurable parameters of the chart and their default values. See [values.yaml](./sd-helm-chart/values.yaml) for all available options.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

#### Global parameters
In case the SD helm chart is used as dependency chart, global parameters can be helpful. 
The following global parameters are supported.

| Parameter | Description | Default |
|-----|-----|-----|
| `global.imageRegistry` | Set to point to the Docker registry where SD and its subchart images (redis, couchdb, kafka) are kept. | null |
| `global.storageClass` | Define storageclass for full SD chart | null |
| `global.sdimages.registry` | Set to point to the Docker registry where SD images are kept | null |
| `global.sdimage.tag` | Set to version of SD (sd-sp) image used during deployment | null |
| `global.prometheus.enabled` | Set to true to deploy Prometheus with SD, see [Enable metrics and display them in Prometheus and Grafana](#enable-metrics-and-display-them-in-prometheus-and-grafana) | null |
| `global.elk.enabled` | Set to true to deploy ElasticSearch with SD, see [Display SD logs and analyze them in Elasticsearch and Kibana](#display-sd-logs-and-analyze-them-in-elasticsearch-and-kibana) | null |
| `global.pullPolicy` | Default imagePullPolicy for images that don't define any. This will not affect couchdb, kafka, and redis images. | Always |

**Note** that global parameters at any time will be ovewritten by its specific defined parameter (those described below).

#### Common parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `sdimages.registry` | Set to point to the Docker registry where SD images are kept | local registry (if using another registry, remember to add "/" at the end, e.g. hub.docker.hpecorp.net/cms-sd/) |
| `sdimages.tag` | Set to version of SD images used during deployment | `3.7.1` |
| `sdimages.pullPolicy` | imagePullPolicy for SD images| Always |
| `install_assurance` | Set to false to disable Closed Loop | `true` |
| `kafka.enabled` | Set it to `true` to enable Kafka | `false` |
| `sdsnmp_adapter.enabled` | Set it to `true` to enable SNMP adapter | `false` |
| `monitoringNamespace` | Declare which namespace Prometheus and ELK pods are deployed. | Namespace provided for helm deployment |
| `serviceAccount.enabled` | Enables Service Account usage | `false` |
| `serviceAccount.create` | Creates a Service Account used to download Docker images from private Docker Registries | `false` |
| `serviceAccount.name` | Sets the Service Account name | null |
| `serviceAccount.imagePullSecrets.name` | Sets the Secret name that containts Docker Registry credentials | null |
| `securityContext.enabled` | Enables the security settings that apply to all Containers in the Pod | false |
| `securityContext.fsGroup` | All processes of the container are also part of the that supplementary group ID | 0 |
| `securityContext.runAsUser` | Specifies that for any Containers in the Pod, all processes run with that user ID | 0 |
| `couchdb.enabled` | Set to false to disable CouchDB | `true` |
| `redis.enabled` | Set to false to disable Redis | `true` |
| `elk.enabled`| Set to true to deploy ElasticSearch with SD, see [Display SD logs and analyze them in Elasticsearch and Kibana](#display-sd-logs-and-analyze-them-in-elasticsearch-and-kibana) | `false` |
| `prometheus.enabled`| Set to true to deploy Prometheus with SD, see [Enable metrics and display them in Prometheus and Grafana](#enable-metrics-and-display-them-in-prometheus-and-grafana) | `false` |
| **sdimage parameters** |  |  |
| `sdimage.tag` | Set to explicit version of sd-sp image used during deployment | latest |
| `sdimage.licenseEnabled` | Set true to use a license file | `false` |
| `sdimage.sshEnabled` | Set true to enable Secure Shell (SSH) Key | `false` |
| `sdimage.metrics_proxy.enabled` | Enables a proxy in port 9991 for metrics and health SD data URLs, that way you don't expose the SD API management in port 9990 | true |
| `sdimage.metrics.enabled` | Enables the SD metrics and health data URLs, set to true if you want to use them without deploying the Prometheus example | false |
| `sdimage.env.SDCONF_activator_rolling_upgrade` | [EXPERIMENTAL] Set to `yes` to enable rolling upgrades | `no` |
| `sdimage.envSDCONF_install_om` | Set to `yes` to enable deployment of the OM solution | `no` |
| `sdimage.env.SDCONF_install_omtmfgw` | Set to `yes` to enable deployment of the OMTMFGW solution | `no` |
| `sdimage.env.SDCONF_activator_db_vendor` | Vendor or type of the database server used by HPE Service Activator. Supported values are Oracle, EnterpriseDB and PostgreSQL | PostgreSQL |
| `sdimage.env.SDCONF_activator_db_hostname`| Hostname of the database server used by HPE Service Activator. If you are not using a K8S deployment, then you need to point to the used database. **Note:** other Helm values can be referenced here using `{{ }}`. For example, a global `sdimage.env.SDCONF_activator_db_hostname` could be set and then referenced as: `sdimage.env.SDCONF_activator_db_hostname: {{ .Values.global.sdimage.env.SDCONF_activator_db_hostname }}` | postgres-nodeport |
| `sdimage.env.SDCONF_activator_db_port`| Port of the database server used by HPE Service Activator. | null |
| `sdimage.env.SDCONF_activator_db_instance`| Instance name for the database server used by HPE Service Activator | sa |
| `sdimage.env.SDCONF_activator_db_user` | Database username for HPE Service Activator to use | sa |
| `sdimage.env.SDCONF_activator_db_password`| Password for the HPE Service Activator database user | secret |
| **sdui_image parameters** |  |  |
| `sdui_image.env.SDCONF_install_omui` | Set to `yes` to enable the OM UI | `no` |

Notice that there are several parameters, global and common, to set the Registry and the Tag. The order of preference is as follows:

For the tag:

1. Each StatefulSet or Deployment`.image.tag` (for each case individually)
2. `sdimage.tag` (only affects SD-SP/SD-CL)
3. `sdimages.tag` (affects all SD pods, this one is set by default in the Values)
4. `global.sdimage.tag` (same as `2`, but with a global scope)

For the registry:

1. Each StatefulSet or Deployment `.image.registry` (for each case individually)
2. `sdimages.registry`
3. `global.sdimages.registry`
4. `global.imageRegistry` (affects all SD images as well as all the dependencies that have a `imageRegistry` defined in their Values file, in the chart that would **exclude** CouchDB.)

This means that if any of the values that have higher priority are found, they would win and take precedence over the others. 

**Example of usage:**
> Install this chart with `latest` SD-CL image, SD-UI `3.6.1`, pulling these two from `hub.docker.hpecorp.net/cms-sd/` and pulling SD-SNMP image from a fictional `some.example.registry/cms-sd/`:
```
helm install sd-helm ./sd-helm-chart --set sdimages.registry=hub.docker.hpecorp.net/cms-sd/,sdimages.tag=latest,sdui_image.image.tag=3.6.1,deployment_sdsnmp.image.registry=some.example.registry/cms-sd/ --values ./sd-helm-chart/values.yaml --namespace sd
```

Service ports using a production configuration are not exposed by default, however the following Helm chart parameters can be set to change the service type (NodePort or LoadBalancer) for some services that requires access from the external network:
#### Service parameters
| Parameter | Description | Default production configuration value | Default testing configuration value |
|-----|-----|-----|-----|
| `prometheus.servicetype` | Set Prometheus service type | ClusterIP | NodePort |
| `prometheus.nodePort` | Set Prometheus node port | null | null |
| `prometheus.grafanaservicetype` | Set Grafana service type | ClusterIP | NodePort |
| `prometheus.nodePort` | Set Grafana node port | null | null |
| `elk.servicetype` | Set ELK service type | ClusterIP | NodePort |
| `elk.nodePort` | Set ELK node port | null | null |
| `elk.kibana.servicetype` | Set Kibana service type | ClusterIP | NodePort |
| `elk.kibana.nodePort` | Set Kibana node port | null | null |
| `service_sdsp.servicetype` | Set SD SP service type | ClusterIP | NodePort |
| `service_sdsp.nodePort` | Set SD SP node port | null | null |
| `service_sdcl.servicetype` | Set SD CL service type | ClusterIP | NodePort |
| `service_sdcl.nodePort` | Set SD CL node port | null | null |
| `service_sdui.servicetype` | Set SD UI service type | ClusterIP | NodePort |
| `service_sdui.nodePort` | Set SD UI node port | null | null |
| `service_sdsnmp.servicetype` | Set SD SNMP Adapter service type | ClusterIP | NodePort |
| `service_sdsnmp.nodePort` | Set SD SNMP Adapter node port | null | null |

If NodePort is set as the service type value then a port number can also be set for the port, otherwise a random port number will be assigned.

##### ReplicaCount Parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `statefulset_sdsp.replicaCount` | Set to 0 to disable Service provisioner nodes | `1` |
| `statefulset_sdcl.replicaCount` | Number of nodes processing assurance and non-assurance requests | `2` |
| `statefulset_sdcl.replicaCount_asr_only` | Number of nodes processing only assurance requests | `0` |
| `sdui_image.replicaCount` | Set to 0 to disable Service director UI | `1` |
| `deployment_sdsnmp.replicaCount` | Set to 0 to disable SNMP Adapter | `1` |

#### Resources parameters
| Parameter | Description | Default |
|-----|-----|-----|
| `sdui_image.memoryrequested`|  Amount of memory a cluster node needs to provide in order to start the UI container. | `300Mb` |
| `sdui_image.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the UI container. | `0.7` |
| `sdui_image.memorylimit` | Max. amount of memory a cluster node will provide to the UI container. No limit by default. | null |
| `sdui_image.cpulimit` | Max. amount of cpu a cluster node will provide to the UI container. No limit by default. | null |
| `sdui_image.loadbalancer` | Activates a load balancer for sd-ui/provisioner connections. Recommended for high availability scenarios . | false |
| `sdui_image.envoy_version` | Docker image version (Bitnami) of the Envoy load balancer used for high availability sd-ui/provisioner connections.  | 1.16.4 |
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
| `fluentd.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Fluentd container in the Prometheus example. | `512Mi` |
| `fluentd.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Fluentd container in the Prometheus example. | `300m` |
| `fluentd.memorylimit` | Max. amount of memory a cluster node will provide to the Fluentd container in the Prometheus example. No limit by default. | `1Gi` |
| `fluentd.cpulimit` | Max. amount of memory a cluster node will provide to the Fluentd container in the Prometheus example. No limit by default. | `500m` |


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
| `elk.elastic.esJavaOpts` | Overrides the default heap size. For more information, check [this](https://www.elastic.co/guide/en/elasticsearch/reference/master/advanced-configuration.html#set-jvm-heap-size) | `-Xmx1g -Xms1g` |
| `elk.kibana.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Kibana container in the ELK example. | `400Mb` |
| `elk.kibana.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Kibana container in the ELK example. | `0.3` |
| `elk.kibana.memorylimit` | Max. amount of memory a cluster node will provide to the Kibana container in the ELK example. No limit by default. | null |
| `elk.kibana.cpulimit` | Max. amount of cpu a cluster node will provide to the Kibana container in the ELK example. No limit by default. | null    |
| `elk.logstash.memoryrequested` |  Amount of memory a cluster node needs to provide in order to start the Logstash container in the ELK example. | `350Mb` |
| `elk.logstash.cpurequested` | Amount of cpu a cluster node needs to provide in order to start the Logstash container in the ELK example. | `0.1` |
| `elk.logstash.memorylimit` | Max. amount of memory a cluster node will provide to the Logstash container in the ELK example. No limit by default. | null |
| `elk.logstash.cpulimit` | Max. amount of cpu a cluster node will provide to the Logstash container in the ELK example. No limit by default. | null |

#### SD configuration parameters

You can use alternative values for some SD config parameters. You can use the following ones in your 'Helm install':

| Parameter | Description | Default |
|-----|-----|-----|
|`SDCONF_asr_adapters_manager_port`| Used to overwrite SNMP Adapter listen port (162 by default). A use-case is when using rootless images, because non root users cannot use port numbers below 1024 | null |
| `sdimage.env.SDCONF_activator_conf_jvm_max_memory` |
| `sdimage.env.SDCONF_activator_conf_jvm_min_memory` |
| `sdimage.env.SDCONF_activator_conf_activation_max_threads` |
| `sdimage.env.SDCONF_activator_conf_activation_min_threads` |
| `sdimage.env.SDCONF_activator_conf_pool_defaultdb_max` |
| `sdimage.env.SDCONF_activator_conf_pool_defaultdb_min` |
| `sdimage.env.SDCONF_activator_conf_pool_inventorydb_max` |
| `sdimage.env.SDCONF_activator_conf_pool_inventorydb_min` |
| `sdimage.env.SDCONF_activator_conf_pool_mwfmdb_max` |
| `sdimage.env.SDCONF_activator_conf_pool_mwfmdb_min` |
| `sdimage.env.SDCONF_activator_conf_pool_resmgrdb_max` |
| `sdimage.env.SDCONF_activator_conf_pool_resmgrdb_min` |
| `sdimage.env.SDCONF_activator_conf_pool_servicedb_max` |
| `sdimage.env.SDCONF_activator_conf_pool_servicedb_min` |
| `sdimage.env.SDCONF_activator_conf_pool_uidb_max` |
| `sdimage.env.SDCONF_activator_conf_pool_uidb_min` |
| `sdimage.env.SDCONF_activator_conf_file_log_pattern` | Sets the log pattern for HPE SA's WildFly file output using [Wildfly's](https://github.com/wildfly/wildfly/blob/master/docs/src/main/asciidoc/_admin-guide/subsystem-configuration/Logging_Formatters.adoc#pattern-formatter) formatters. | null |
| `sdui_image.env.SDCONF_sdui_log_format_pattern` | Sets the log pattern for SD UI using [Log4js](https://github.com/log4js-node/log4js-node/blob/master/docs/layouts.md#pattern-format) formatters. | null |


#### Kafka and Zookeeper configuration parameters

You can use alternative values for some Kafka and Zookeeper config parameters. You can use the following ones in your 'Helm install':

| Parameter | Description | Default |
|-----|-----|-----|
| `kafka.replicacount` | Number of nodes for the Kafka cluster  | 3 |
| `kafka.defaultReplicationFactor` | Default replication factors for automatically created topics | 3 |
| `kafka.offsetsTopicReplicationFactor` | The replication factor for the offsets topic  | 3 |
| `kafka.transactionStateLogMinIsr` | The replication factor for the transaction topic  | 3 |
| `kafka.persistence.enabled` | Used to enable Kafka data persistence using kafka.persistence.storageClass  | true |
| `kafka.persistence.storageClass` | storageClass used for persistence | sdstorageclass |
| `kafka.resources.request.memory`|  Amount of memory a cluster node needs to provide in order to start the Kafka containers. | `256Mi` |
| `kafka.resources.request.cpu` | Amount of cpu a cluster node needs to provide in order to start the Kafka containers. | `250m` |
| `kafka.resources.limits.memory` | Max. amount of memory a cluster node will provide to the Kafka containers. | `1Gi` |
| `kafka.resources.limits.cpu` | Max. amount of cpu a cluster node will provide to the Kafka containers. | `400m` |
| `kafka.securityContext.enabled` | Security context for the Kafka pods  | false  |
| `kafka.securityContext.fsGroup` | Folders groupId used in Kafka pods persistence storage | 1001 |
| `kafka.securityContext.runAsUser` |  UserId used in Kafka pods | 1001 |
| `kafka.affinity` | affinity/antiaffinity policy used | Distributes Kafka pods between all nodes in K8S cluster |
| `kafka.zookeeper.replicacount` | Number of replicas for the Zookeeper cluster  | 3 |
| `kafka.zookeeper.persistence.enabled` | Used to enable Zookeeper data persistence using kafka.persistence.storageClass  | true |
| `kafka.zookeeper.persistence.storageClass` | storageClass used for persistence | sdstorageclass |
| `kafka.zookeeper.resources.request.memory`|  Amount of memory a cluster node needs to provide in order to start the Zookeeper containers. | `256Mi` |
| `kafka.zookeeper.resources.request.cpu` | Amount of cpu a cluster node needs to provide in order to start the Zookeeper containers. | `250m` |
| `kafka.zookeeper.resources.limits.memory` | Max. amount of memory a cluster node will provide to the Zookeeper containers. | `1Gi` |
| `kafka.zookeeper.resources.limits.cpu` | Max. amount of cpu a cluster node will provide to the Zookeeper containers. | `400m` |
| `kafka.zookeeper.securityContext.enabled` | Security context for the Zookeeper pods  | false  |
| `kafka.zookeeper.securityContext.fsGroup` | Folders groupId used in Zookeeper pods persistence storage | 1001 |
| `kafka.zookeeper.securityContext.runAsUser` |  UserId used in Zookeeper pods | 1001 |
| `kafka.zookeeper.affinity` | affinity/antiaffinity policy used | Distributes Zookeeper pods between all nodes in K8S cluster |


#### CouchDB configuration parameters

You can use alternative values for some CouchDB config parameters. You can use the following ones in your 'Helm install':

| Parameter | Description | Default |
|-----|-----|-----|
| `couchdb.enabled` | Activates or deactivates the CouchDB deployment  | true |
| `couchdb.createAdminSecret` | If createAdminSecret is enabled a Secret called <ReleaseName>-couchdb will be created containing auto-generated credentials  | false |
| `couchdb.clusterSize` |  Number of nodes for the CouchDB cluster    | 3 |
| `couchdb.persistentVolume.enabled` | Activates or deactivates the CouchDB data persistence | true |
| `couchdb.persistentVolume.storageClass` | Storageclasss used when persistence is enabled | sdstorageclass |
| `couchdb.couchdbConfig.couchdb.uuid` | Unique identifier for this CouchDB server instance  | decafbaddecafbaddecafbaddecafbad |
| `couchdb.initImage.pullPolicy` | Pull policy for CouchDB initImage | IfNotPresent |
| `couchdb.affinity` | affinity/antiaffinity policy used | Distributes CouchDB pods between all nodes in K8S cluster |
| `couchdb.dns.clusterDomainSuffix` | This is used to generate FQDNs for peers when joining the CouchDB cluster  | cluster.local |

#### Redis configuration parameters

You can use alternative values for some Redis config parameters. You can use the following ones in your 'Helm install':

| Parameter | Description | Default |
|-----|-----|-----|
| `redis.enabled` | Activates or deactivates the Redis deployment  | true |
| `redis.cluster.enabled` | Enables Redis as a cluster with a master/slave structure | true |
| `redis.cluster.slaveCount` |  Number of slave nodes for the Redis cluster    | 2 |
| `redis.redisPort` | Port used in Redis to receive incoming requests | true |
| `redis.existingSecret` | Secret that will be used to recover the Redis password | redis-password |
| `redis.existingSecretPasswordKey` | Link inside the Secret where the Redis password is stored  | password |
| `redis.metrics.enabled` | If enabled Redis metrics will be xposed to Promteheus example | false |
| `redis.securityContext.enabled` | Security context for the Redis pods  | false  |
| `redis.securityContext.fsGroup` | Folders groupId used in Redis pods persistence storage | 1001 |
| `redis.securityContext.runAsUser` |  UserId used in Redis pods | 1001 |
| `redis.master.persistence.enabled` |  Activates or deactivates the Redis master node data persistence  | true |
| `redis.master.persistence.storageClass` |  Storageclasss used when persistence is enabled    | sdstorageclass |
| `redis.master.resources.request.memory` |   Amount of memory a cluster node needs to provide in order to start the Redis containers  | 256Mi |
| `redis.master.resources.request.cpu` |   Amount of memory a cluster node needs to provide in order to start the ZookeRediseper containers.   | 100m |
| `redis.master.affinity` | affinity/antiaffinity policy used | Distributes Redis master pods between all nodes in K8S cluster |
| `redis.slave.persistence.enabled` |   Activates or deactivates the Redis slave nodes data persistence   | true |
| `redis.slave.persistence.storageClass` |  Storageclasss used when persistence is enabled    | sdstorageclass |
| `redis.slave.resources.request.memory` |   Amount of memory a cluster node needs to provide in order to start the Redis containers   | 256Mi |
| `redis.slave.resources.request.cpu` |   Amount of memory a cluster node needs to provide in order to start the Redis containers.   | 100m |
| `redis.slave.affinity` | affinity/antiaffinity policy used | Distributes Redis slave pods between all nodes in K8S cluster |

#### ELK configuration parameters

| Parameter | Description | Default |
|-----|-----|-----|
| `elk.logstash.extraPipelines` | Allows to add extra pipeline files in `/usr/share/logstash/pipeline/` to combine with the default one. More information about this feature can be found [here](#configuring-logstash-pipeline). | {} |
| `elk.elastic.extraVolumes` | Additional volumes | null |
| `elk.elastic.extraVolumeMounts` | Additional mount paths | null |
| `elk.elastic.extraInitContainers` | Extra `initContainers` | null |

#### Add custom variables within a ConfigMap
On the previous sections we have seen many customizable parameters. These parameters are specified in the [values.yaml](./sd-helm-chart/values.yaml) file. In addition, you can add even more custom parameters within a ConfigMap. These are the steps to create and use a ConfigMap to add your custom variables:

1. Create a ConfigMap with the desired variables.
```
---
apiVersion: v1
kind: ConfigMap
metadata:
    name: <config-map-name>
    namespace: sd
data:
    SDCONF_sdui_account_hierarchical: "yes"
```

2. Run the `helm install` command and set the ConfigMap name using the `--set` parameter:
```
helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<repo>,sdimages.tag=<image-tag>,sdui_image.env_configmap_name=<config-map-name> --namespace sd
```

**NOTE**: This can be done also creating your own `values-custom.yaml` file and adding the parameters to it.
```
sdui_image:
    env_configmap_name: <config-map-name>
```

Then just point to this file when you run the `helm install` command:
```
helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<repo>,sdimages.tag=<image-tag> --values ./sd-helm-chart/values-custom.yaml --namespace sd
```

#### Labeling pods and services
Extra labels can be added to SD pods, as well as the pods created in Prometheus and ELK scenarios, using the `podLabels` parameter. For instance:
```
sdimage:
  podLabels:
    key1: value1
    key2: value2
    ...
```
Notice as many labels as needed can be added.

These labels are particularly useful to cluster administrators as they allow to run commands like:
```
kubectl delete pod -l key1=value1 -n sd
```
This would delete all the pods with the label `key1: value1` in the `sd` namespace.

There are label parameters in `sdimage`, `sdui_image` and `deployment_sdsnmp` to allow adding labels to these pods **separately**. The ones in `elk` and `prometheus` would apply to **all** the pods instantiated in these scenarios. For example:
```
elk:
  labels:
    key1: value1
```
would add the label `key1: value1` to the Elasticsearch, Logstash and Kibana pods.

**Services** can be labeled in a similar way. For this, there is a `serviceLabels` parameter available for SD services in `sdimage`, `sdui_image` and `deployment_sdsnmp`, as well as specific `labels` parameters that can override these in each service's section of the values file, for instance, `service_sdui.labels`. Labeling external third-party services is also supported through each service's `labels` parameter, such as `service_elk.labels` or `service_grafana.labels`.

Full list of specific service labels supported:

| Service | Values section |
|-----|-----|
| `sd-sp & headless-sd-sp` | service_sdsp.labels | 
| `sd-cl & headless-sd-cl` | service_sdcl.labels |
| `sd-ui` | service_sdui.labels |
| `sd-snmp-adapter` | service_sdsnmp.labels |
| `sd-sp-prometheus` | service_sdsp_prometheus.labels |
| `sd-cl-prometheus` | service_sdcl_prometheus.labels |
| `elasticsearch-service & elasticsearch-service-headless` | service_elk.labels |
| `grafana & grafana-headless` | service_grafana.labels |
| `sd-kube-state-metrics` | service_sd_ksm.labels |

For instance:
```
service_sdsp
  labels:
    key1: value1
```
adds the label `key1: value1` to the sd-sp service.

### Upgrade HPE Service Director Deployment
To upgrade the Helm chart use the helm `upgrade` command to apply the changes (E.g.: change parameters):

    helm upgrade sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<repo>,sdimages.tag=<image-tag> --namespace sd

The following command must be executed to upgrade Service Director in a production environment:

    helm upgrade sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<repo>,sdimages.tag=<image-tag> --namespace sd -f values-production.yaml

### Uninstall HPE Service Director Deployment

To uninstall the Helm chart execute the following command:

    helm uninstall sd-helm --namespace=sd

## Service Director High Availability
When installing the SD helm chart, you can decide to increase the number of pods for the SD deployment. To do so, please adjust the number of the replica count parameters when you do the helm install or upgrade.

![SD-HA](/kubernetes/docs/images/SD-HA.png)

You can adjust the following replica counts for the pods in the Helm chart [ReplicaCount Parameters](#replicacount-parameters)

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

For a HA deployment of a Pod, each replicacount shall be set to atleast the value 2. E.g.:

    --set statefulset_sdsp.replicaCount=2,sdui_image.replicaCount=2

K8s will ensure the number of replicas is always the desired state of the running pods in the Helm deployment.

Find more information here about [Scaling Best Practices](/kubernetes/docs/ScalingBestPractices.md).

## Enable metrics and display them in Prometheus and Grafana
Prometheus and Grafana make it extremely easy to monitor just about any metric in your Kubernetes cluster, they can be deployed alongside "exporters" to expose cluster-level Kubernetes object metrics as well as machine-level metrics like CPU and memory usage.

This extra deployment can be activated during the helm chart execution using the following parameter:

    prometheus.enabled=true


Two dashboards are preloaded in Grafana in order to display information about the performance of SD pods in the cluster and Service Activator's metrics.

Before deploying Prometheus example, a namespace must be created, The default name is "monitoring", it can be another of your choice but the parameter "monitoringNamespace" with the new name must be added to the "helm install" .
In order to generate it, run:

    kubectl create namespace monitoring

and this repo must be added using the following command:

    helm repo add bitnami https://charts.bitnami.com/bitnami

When Prometheus is enabled the Service Director pod will include a sidecar container called Fluentd that exposes SA alert metrics to Prometheus.

You can find more information about how to run the example and how to connect to Grafana and Prometheus [here](/kubernetes/docs/alertmanager)

By default, Redis metrics are not included when enabling metrics. To enable them the following parameter needs to be added to the helm chart execution:

    redis.metrics.enabled=true

This will also preload a Redis example graph in Grafana.

Some parts of the Prometheus example can be disabled in order to connect to another Prometheus or Grafana server that you already have in place. These are the extra parameters:

| Parameter | Description | Default |
|-----|-----|-----|
| `prometheus.server_enabled` |  If set to false the Prometheus and Grafana pods will not deploy. Use the values in this [config](./sd-helm-chart/templates/prometheus/prometheus/configmap.yml) file to configure SD metrics to an alternate Prometheus server. Use these [dashboards](./sd-helm-chart/templates/prometheus/prometheus/grafana/)  to display SD metrics to an alternate Grafana server | `true` |
| `prometheus.alertmanager_enabled` | If set to false the Alertmanager container will not deploy in the Prometheus pod. You can find more information about the Alertmanager [here](/kubernetes/docs/alertmanager/README.md) | `false` |
| `prometheus.grafana.enabled` | If set to false the Grafana pod will no deploy. Use these [dashboards](./sd-helm-chart/templates/prometheus/prometheus/grafana/) to display SD metrics to an alternate Grafana server | `true` |

### Additional metrics 

For retrieving the metrics from SD/HPSA you can access the wildfly management api on port 9991 for sd-sp or sd-cl pods, it is activated when you deploy the Prometheus example. If you want to access to these metrics without deploying the Prometheus example you have to add two parameters during the helm install process:

`sdimage.metrics.enabled=true, sdimage.metrics_proxy.enable=true`

`sdimage.metrics.enabled` enables the SD metrics and health data URLs
`sdimage.metrics_proxy.enabled` enables a proxy in port 9991 for metrics and health SD data URLs, that way you don't expose the full wildfly management API 

Setting `sdimage.metrics_proxy.enabled` to true or deploying the Prometheus example will add an extra Envoy sidecar container to avoid the full wildfly management API exposure, that way only the URL for the metrics needed is exposed at http://sd-sp:9991/metrics or http://sd-cl:9991/metrics


### Troubleshooting


- Issue: System related metrics (for example, *CPU usage*) are not been retrieved.
- Solution: Install Kubernetes metrics server. Installation guide can be found in https://hewlettpackard.github.io/Docker-Synergy/blog/install-metrics-server.html


## Display SD logs and analyze them in Elasticsearch and Kibana
The ELK Stack helps by providing us with a powerful platform that collects and processes data from multiple SD logs, stores logs in one centralized data store that can scale as data grows, and provides a set of tools to analyze those logs.

This extra deployment can be activated during the helm chart execution using the following parameter:

    elk.enabled=true

Several Kibana indexes are preloaded in Kibana in order to display logs of Service Activator's activity.

ELK will deploy in the default namespace if no namespace is set in the helm install parameter, you can also use the parameter "monitoringNamespace" to set a customized namespace for ELK.

Elasticsearch requires vm.max_map_count to be at least 262144, therefore before ELK deployment check if your OS already sets up this number to a higher value.

The following logs will be available to Elasticsearch and Kibana:

- Wildfly server logs as wildfly-yyyy.mm.dd
- Server log from UOC as uoc-yyyy.mm.dd
- Service Activator workflow manager logs as sa_mwfm-yyyy.mm.dd
- HPE SA resource manager logs as sa_resmgr-yyyy.mm.dd
- Redis messages redis-input-YYYY.MM.dd

Fluentd is the default option in order to collect the logs and send them to Elasticsearch pod. If you want to use Filebeat/Logstash as the default containers to collect the logs you have to set the parameter `elk.fluentd.enabled=false` during helm install execution.

The following SD log information will be read by Fluentd or Filebeat (depending on the value of `elk.fluentd.enabled`):

- `SD container`: WildFly log using the following path - /opt/HP/jboss/standalone/log/
- `SD container`: Service Activator logs using the following path - /var/opt/OV/ServiceActivator/log/
- `SD container`: SNMP adapter log using the following path - /opt/sd-asr/adapter/log/
- `SD UI container`: UOC log using the following path - /var/opt//uoc2/logs

The Filebeat/Logstash option will also expose Redis logs to Elasticsearch pod.

You can check if the SD logs indexes were created and stored in Elasticsearch using the Kibana web interface, you can find more information [here](../../docs/Kibana.md)

Raising SD alerts with ELK is optional in the SD helm chart and it is not activated by default, some additional setup must be done. You can find more information [here](../../docs/elastalert/README.md)

Some parts of the ELK example can be disabled in order to connect to another Elasticsearch or Logstash server that you already have in place. These are the extra parameters:

| Parameter | Description | Default |
|-----|-----|-----|
| `elk.enabled` |  If set to false the ELK pods won't deploy | `false` |
| `elk.elastalert.enabled` |  If set to false the Elastalert pod won't deploy. Use the parameter `elk.elastalert.elkserver` to point to an alternative Elasticsearch server | `false` |
| `elk.fluentd.enabled` |  If set to false the Fluentd pod won't deploy and the Filebeat/Logstash pods will be deployed instead | `true` |
| `elk.elastic.enabled` |  If set to false the Kibana and Elasticsearch pods will not deploy. Use the parameter `elk.logstash.elkserver` to point to an alternate server| `true` |
| `elk.kibana.enabled` | If set to false the Kibana pod will no deploy. Use elasticsearch exposed service to connect to an alternate Kibana server to the ELK pod | `true` |
| `elk.logstash.enabled` |  If set to false the logstash pod will not deploy. Use the parameter `elk.logstash.elkserver` to point to an alternate elasticsearch server| `true` |
| `elk.filebeat.enabled` |  If set to false the Filebeat container will not deploy. Use the parameter `elk.filbeat.logstashserver` to point to an alternate logstash server| `true` |

### Configuring the log format
SD-SP log format can be configured directly from the Helm chart with the parameter `sdimage.env.SDCONF_activator_conf_file_log_pattern` using Wildfly's logging [formatters](https://github.com/wildfly/wildfly/blob/master/docs/src/main/asciidoc/_admin-guide/subsystem-configuration/Logging_Formatters.adoc).

The same can be done with SD-UI using a similar parameter `sdui_image.env.SDCONF_sdui_log_format_pattern`, in this case using log4js formatters, although they are pretty similar to Wildfly's, there could be differences. To learn more about log4js formatters, click [here](https://github.com/log4js-node/log4js-node/blob/master/docs/layouts.md#pattern-format)

**Important note:**
We use [grok](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html) in our Logstash configuration in order to parse SD logs. If the default log format is modified (any of the variables are not left empty), **the default grok filter must me changed as well** to match the new format, otherwise Logstash will not be able to parse the logs. We provide 2 variables to allow changing these filters for each case: `elk.logstash.sdsp_grokpattern` and `elk.logstash.sdui_grokpattern`.

 **Note:** these variables need to be passed between single quotes first **and** double quotes next to avoid YAML syntax errors, like: 
```
'"%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE:loglevel}\s+\[(?<logger>[^\]]+)\] \((?<thread>.+?(?=\) ))\) %{GREEDYDATA:message}"'
``` 
Alternatively you could skip single quotes and use escape [characters](https://yaml.org/spec/current.html#id2517668).
### Creating your own grok filters
Simply put, grok is a macro to simplify and reuse regexes. The basic syntax of a grok expression is `%{PATTERN:FieldName}`. Logstash will use these grok expression to parse the log data and turn it into something structured and queryable. A table is provided below to help you translate these layout formatters and find an appropiate grok expression, in case you decide to change the default layout and need to adapt the grok filter. 
Grok comes with built-in patterns for filtering items such as words, numbers, and dates. For a list of these patterns, see [this](https://github.com/elastic/elasticsearch/blob/master/libs/grok/src/main/resources/patterns/grok-patterns). Essentially, grok is based upon a combination of regular expressions, so if you cannot find the pattern you need, you can write your own like `(?<custom_field>custom pattern)` as indicated in some of the examples in the table below:

| Description | Wildfly's layout formatter | Logstash Grok pattern|
| :---         |     :---:      |   :---: |
| Date (general format but could vary)  | %d     | `%{TIMESTAMP_ISO8601}:timestamp`    |
| Category of the logging event    | %c       | `(?<logger>[A-Za-z0-9$_.]+)`  |
| Thread  | %t  | `\((?<thread>.+?(?=\) ))\)`  |
| Log Level (INFO, WARN, ..) with precision specified | %-5p | `%{NOTSPACE:loglevel}` or  `%{LOGLEVEL:loglevel}`  |
| Log trace -> divided in 3 parts: <br /> **%s**: simple formated message. This will not include the stack trace if a cause was logged. <br /> **%e**: prints the full stack trace. <br /> **%n**: platform independent line separator. | %s%e%n  | `%{GREEDYDATA:message}`  |
| Class of the code calling the log method  | %C | `(?<class>[A-Za-z0-9$_.]+)`  |
| Name of the module the log message came from  | %D | `%{NOTSPACE:module}`  |
| Name of the class that logged the message. Similar to `%C`, differs in how long the classname will be. | %F | `%{JAVAFILE:class}` |
| Short host name  | %h | `%{NOTSPACE:hostname}` |
| Qualified host name  | %H | `%{HOSTNAME:fqdn}` |
| Process ID  | %i | `%{NUMBER:processid}`  |
| Resource bundle key | %k | `%{NOTSPACE:key}`  |
| Location information  | %l | `%{JAVASTACKTRACEPART:location}`  |
| Line number of the caller  | %L | `{NONNEGINT:line}`  |
| Formatted message inclusing any stack traces  | %m | `%{GREEDYDATA:message}`  |
| Callers method name| %M | `%{NOTSPACE:method}`  |
| Platform independent line separator  | %n | `$`  |
| Name of the process  | %N | `%{NOTSPACE:process}`  |
| Level of the logged message  | %p | `%{LOGLEVEL:loglevel}` |
| Localized level of the logged message | %P | `%{WORD:loclevel}`  |
| Relative number of milliseconds since the given base time from the log message | %r | `%{INT:milisecs}`  |
| Version of the module  | %v | `%{NUMBER:version}` |
| Nested diagnostic context entries  | %x | `(%{NOTSPACE:ndc})?` |
| Mapped diagnostic context entry | %X | `\{(?<mdc>(?:\{[^\}]*,[^\}]*\})*)\}`  |

**Caution:** Use this table as reference. Some of these translations may not work right off the bat and may need customization. We recommend using [this website](http://grokdebug.herokuapp.com) to construct and test your grok expression.
#### Example:
Setting the variable like this (this also is the default format):
```
sdimage.log_format: "%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n"
```
Would produce log messages with the following format:
```
2021-04-26 11:56:32,311 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0051: Admin console listening on http://127.0.0.1:9990
```
Grok expression needed by Logstash to parse and dissect the log shown above:
```
%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE:loglevel}\s+\[(?<logger>[^\]]+)\] \((?<thread>.+?(?=\) ))\) %{GREEDYDATA:message}
```
You could pass it with the `--set` command when installing the Helm chart like:
```
helm install sd-helm ./sd-helm-chart --set install_assurance=false,sdimages.registry=hub.docker.hpecorp.net/cms-sd/,elk.enabled=true,elk.logstash.sdsp_grokpattern='"%{TIMESTAMP_ISO8601:timestamp} %{NOTSPACE:loglevel}\s+\[(?<logger>[^\]]+)\] \((?<thread>.+?(?=\) ))\) %{GREEDYDATA:message}"' --values ./sd-helm-chart/values.yaml --namespace sd
```

#### RFC 5424
A common way to format logs is using the RFC 5424 standard. Given its popularity, grok comes with predefined patterns to easily parse messages in this format. You can check the available patterns related to this standard [here](https://github.com/elastic/elasticsearch/blob/master/libs/grok/src/main/resources/patterns/linux-syslog).

Thanks to the built-in patterns in grok, this log message:
```
<165>1 2003-10-11T22:14:15.003Z mymachine.example.com evntslog - ID47 [exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"] Test application event log entry...
```
Could be processed by grok with an expression as simple as:
```
%{SYSLOG5424LINE}
```
**Note:** if this grok expression is used instead of a custom pattern, notice it will dissect and name the fields in a certain way (i.e. "message" would become "syslog5424_msg", etc).

### Configuring Logstash pipeline

As can be read in the official [docs](https://www.elastic.co/guide/en/logstash/current/pipeline.html), the Logstash event processing **pipeline** has three stages: inputs → filters → outputs. These pipelines are passed to Logstash as `.conf` files to the `/usr/share/logstash/pipeline/` directory. SD Helm chart ELK example has a preconfigured pipeline but additional ones can be added using the `elk.logstash.extraPipelines` parameter. These extra pipelines are mounted into Logstash along our default and then combined into a single one. This parameter can be used as showed in the example below:

```
elk:
  logstash:
    extraPipelines:
      eo.conf: |
        input {
          host => "redis-master.{{.Values.namespace}}.svc.cluster.local"
          password => "secret"
          type => "redis-input"
          data_type => "pattern_channel"
          port => "6379"
          key => "*"
          codec => plain { charset=>"ASCII-8BIT" }
        } 
        filter {
          if [type] == "eo-keycloak-audit" {
           # Remove ANSI color code
           mutate {
           gsub => ["message", "\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]", ""]
          }
        } 
        .
        .
        .
        output {
            ...
        }
```
A great thing about this Logstash feature is that, for example, if two or more pipeline files share the same `output`, they will be merged and use a single one, so if it is already configured in one of the `.conf` files, it does not have to be passed again.
## Persistent Volumes

### How to enable Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB
A persistent volume (PV) is a cluster resource that you can use to store data for a pod and it persists beyond the lifetime of that pod. The PV is backed by networked storage system such as NFS.

Redis, Kafka/Zookeeper and CouchDB come with data persistance disable by default, in order to enable a persistent volume for some of them you have to start the helm chart with the following parameters:

    kafka.persistence.enabled=truee
    kafka.zookeeper.persistence.enabled=truee
    couchdb.persistentVolume.enabled=truee
    redis.master.persistence.enabled=truee

Therefore the following command must be executed to install Service Director (Closed Loop example):

    helm install sd-helm sd-chart-repo/sd_helm_chart --set kafka.persistence.enabled=true,kafka.zookeeper.persistence.enabled=true,couchdb.persistentVolume.enabled=true,redis.master.persistence.enabled=true,sdimages.registry=<repo>,sdimages.tag=<image-tag> --namespace sd

Previously to this step some persistent volumes must be generated in the Kubernetes cluster. Some Kubernetes distributions as Minikube or MicroK8S create the PVs for you, therefore the stotage persitence needed for Kafka, Zookeeper, Redis , CouchDB or database pods are automatically handled. You can read more information [here](/kubernetes/docs/PersistentVolumes.md#persistent-volumes-in-single-node-configurations).

If you have configured dynamic provisioning on your cluster, such that all storage claims are dynamically provisioned using a storage class, as it is described [here](/kubernetes/docs/PersistentVolumes.md#persistent-volumes-in-multi-node-configurations) you can skip the following steps.

If don't you have dynamic provisioning on your cluster then you need to create it manually and a default storage class, as it is described [here](/kubernetes/docs/PersistentVolumes.md#local-volumes-in-k8s-nodes).

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

    helm install sd-helm sd-chart-repo/sd_helm_chart --set ingress.enabled=true,,ingress.hosts[0].name=sd.native.ui.com,ingress.hosts[0].sdenabled=true,ingress.hosts[0].sduienabled=false,ingress.hosts[1].name=sd.uoc.ui.com,ingress.hosts[1].sdenabled=false,ingress.hosts[1].sduienabled=true --namespace sd

The ingress configuration will setup two different host, one for Service Director native UI at:

    http://sd.native.ui.com/sd

and a Service Director Unified OSS Console (UOC) at:

    http://sd.uoc.ui.com/sdui

Another example of an installation of Service Director with Ingress enabled, with a single host with no name, using your cluster IP address:

    helm install sd-helm sd-chart-repo/sd_helm_chart --set ingress.enabled=true --namespace sd

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


## dbsecret

A default DB password can be found in [the secret object](/kubernetes/helm/charts/sd-helm-chart/templates/secret.yaml) , if you are in a production environment the dbpasssword value will be different and you have to point to a new one inside a new secret object. In order to override the DB password you just deploy the following secret previously to the SD deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dbsecret
type: Opaque
data:
  dbpassword: xxxxxx

```

where "xxxxxx" is your DB password in base64 format. In order to activate it during deployment you have to include the parameter sdimage.env.SDCONF_activator_db_password_name=dbsecret in your "helm install" command.


## Healthcheck pod for Service Director 

To manage containers effectively user needs a way to check the health of the SD deployment, some information as if the pods started or are working correctly is required. SD deployment uses a health check pod to determine if instances of the SD app are running and responsive.

Since the separate components work independently, each part will keep running even after other components have failed. A view of the global status is needed at some point, with information if SD is still providing its functionality . 

Some pods might be still in the initialization stage and not yet ready to receive and process requests but they are not needed for the core functionality, therefore the healthstatus pod can inform of that incident and it will report SD is still active. 


### Control healthcheck with rules 

To decide if the SD deployment is healthy some rules must be applied in the healthcheck pod: the values file from the SD helm chart contains a "healthcheck.labelfilter" parameter as the following:
```
 healthcheck:
    labelfilter:
      unhealthy:
        app: sd-sp
        app: postgres
      degraded:
        app: sd-ui
        app: couchdb
        app: redis
        app.kubernetes.io/name: kafka
        app.kubernetes.io/name: zookeeper
        app: sd-healthcheck
 ```   
Healthcheck will monitor the pods with labels included in "healthcheck.labelfilter.unhealthy" and "healthcheck.labelfilter.degraded" parameters. 

The values unhealthy and degraded follow the following rules:

Healthcheck will return a "healthy" status response  based on the following:
   
   - Any of each deployment/statefulset labeled as "unhealthy" has all its instances up and running

Healthcheck will return a "degraded" status response based on the following:
   
   - Any of each deployment/statefulset labeled as "unhealthy" has some of its instances not up and running, or
   - Any of each deployment/statefulset labeled as "degraded" has all its instances not up and running


Healthcheck will return a "unhealthy" status response  based on the following:
   
   - Any of each deployment/statefulset labeled as "unhealthy" has all of its instances not up and running 



        
### Health check interface and output


Healthcheck exposes an API in port 8080 in the healthcheck pod,  it returns 200 OK unless there is some internal error in the process. The data returned is in json format.

The healthcheck pod exposes the port 8080 internally,  in order to access from ourside the cluster you can use this command:

      kubectl sd-healthcheck  28015:8080
       
The healthcheck URL will be available at port 28015 of your K8S cluster IP.

The url to access the healthcheck information is the following

     http://yourclusterip:xxxxx/healthcheck

where xxxxx is port 8080 or an external port mapped to port 8080

The json output contains a "healthstatus" key with the values "healthy", "degraded" or "unhealthy" as describe previously. It will also contain a "application" key containing a description of the status of all pods monitored by the "healthcheck.labelfilter" parameter . 
The returned code is 200 OK.

```
{
  "name": "sd",
  "healthstatus": "unhealthy",
  "description": "HPE Service director app health status",
  "component": [
    {
      "pod": [
        {
          "containers_ready": "1/1",
          "container_restarts": 0,
          "name": "redis-master-0",
          "status": "Running"
        }
      ],
      "replicas": 1,
      "name": "redis-master",
      "healthstatus": "healthy",
      "podstatus": {
        "running": 1,
        "waiting": 0,
        "failed": 0,
        "succeeded": 0
      },
      "type": "statefulset"
    },
    {
      "pod": [
        {
          "containers_ready": "2/2",
          "container_restarts": 0,
          "name": "sd-ui-0",
          "status": "Running"
        },
        {
          "containers_ready": "1/2",
          "containers_restarts": 0,
          "name": "sd-ui-1",
          "status": "Running"
        }
      ],
      "replicas": 2,
      "name": "sd-ui",
      "healthstatus": "healthy",
      "podstatus": {
        "running": 2,
        "waiting": 0,
        "failed": 0,
        "succeeded": 0
      },
      "type": "statefulset"
    },
  .....
```
  
If there is any error during the API request a 400 HTTP code will be returned with a json response. The response will contain a key called "error" with a description pointing to healthcheck container log file.

### Deploy healthcheck with the SD helm chart

Healthcheck pod comes as optional in SD helm chart. You can deploy it using the parameter "healthcheck.enabled=true" during the helm install phase.

A Service Account must be required in order to give enough permissions to run the pod, as in Openshift deployments. If this is your case then you have to enable it using the parameter "healthcheck.serviceaccount.enabled=true" . If you want to use an already created Service Account then you can override the parameter "healthcheck.serviceaccount.name" with your own value, otherwise a Service Account called "sd-healthcheck" will be created and a Role and RoleBinding object will be used.

### Healthcheck parameters

| Parameter | Description | Default |
|-----|-----|-----|
| `healthcheck.enabled` | If set to false the pod won't deploy. | false |
| `healthcheck.tag` | Set to version of SD images used during deployment . | 1.0.0 |
| `healthcheck.registry` |  Set to point to the Docker registry where healthcheck image is kept. If set to null defaults to SD image registry | null |
| `healthcheck.name` | Name of the container's image. | sd-healthcheck |
| `healthcheck.labelfilter.unhealthy` | List of pods to monitor with the 'unhealthy' rule | list of pods |
| `healthcheck.labelfilter.degraded` | List of pods to monitor with the 'degraded' rule | list of pods |
| `healthcheck.resources.requests.memory`|  Amount of memory a cluster node needs to provide in order to start the container. | 256Mi |
| `healthcheck.resources.requests.cpu` | Amount of cpu a cluster node needs to provide in order to start the container. | 250m |
| `healthcheck.resources.limits.memory` | Max. amount of memory a cluster node will provide to the container. | 500mi |
| `healthcheck.resources.limits.cpu` | Max. amount of cpu a cluster node will provide to the container. | 400m |
| `healthcheck.securityContext.runAsUser` |  UserId used in healthcheck pods if securityContext.enabled is set to true| 1001 |
| `healthcheck.securityContext.fsGroup` | Folders groupId used in pods persistence storage if securityContext.enabled is set to true| 1001 |
| `healthcheck.serviceaccount.enabled` | If enabled a security account will be added to pod| false |
| `healthcheck.serviceaccount.name` | Name of the security account assigned to the pod (must exist in the cluster). If set to 'sd-healthcheck' a Role and SecurityAccount will be generated for the pod | sd-healthcheck |
