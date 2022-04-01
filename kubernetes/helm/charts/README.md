# HPE Service Director Helm chart Deployment

## Contents

* [HPE Service Director Helm chart Deployment](#hpe-service-director-helm-chart-deployment)
  * [Introduction](#introduction)
  * [Deployment diagram](#deployment-diagram)
  * [Prerequisites](#prerequisites)
    * [1. Deploy database](#1-database)
    * [2. Namespace](#2-namespace)
    * [3. Resources](#3-resources)
      * [Resources in testing environments](#resources-in-testing-environments)
      * [Resources in production environments](#resources-in-production-environments)
    * [4. Kubernetes version](#4-kubernetes-version)
  * [Deploying Service Director](#deploying-service-director)
    * [Accessing SD Docker images from public DTR](#accessing-sd-docker-images-from-public-dtr)
    * [Using a Service Director license](#using-a-service-director-license)
    * [Adding Secure Shell (SSH) Key configuration for SD](#adding-secure-shell-key-configuration-for-sd)
    * [Using Service Account](#using-service-account)
    * [Adding Security Context configuration](#adding-security-context-configuration)
    * [Deploying SD Closed Loop](#deploying-sd-closed-loop)
      * [Non-root deployment](#non-root-deployment)
    * [Deploying SD Provisioner](#deploying-sd-provisioner)
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
      * [EFK resources parameters](#efk-resources-parameters)
      * [SD configuration parameters](#sd-configuration-parameters)
      * [Kafka and Zookeeper configuration parameters](#kafka-and-zookeeper-configuration-parameters)
      * [Adding custom variables within a ConfigMap](#adding-custom-variables-within-a-configmap)
      * [Labeling pods and services](#labeling-pods-and-services)
      * [Thirdparty registry options](#thirdparty-registry-options)
    * [Upgrading HPE Service Director Deployment](#upgrading-hpe-service-director-deployment)
    * [Uninstalling HPE Service Director Deployment](#uninstalling-hpe-service-director-deployment)
  * [Service Director High Availability](#service-director-high-availability)
  * [Enabling metrics and displaying metrics in Prometheus and Grafana](#enabling-and-displaying-metrics-in-prometheus-and-grafana)
    * [HealthCheck pod metrics](#healthcheck-pod-metrics)
    * [Additional metrics](#additional-metrics)
    * [Troubleshooting](#troubleshooting)
  * [Displaying and analyzing SD logs in Elasticsearch and Kibana](#displaying-and-analyzing-sd-logs-in-elasticsearch-and-kibana)
    * [Configuring the log format](#configuring-the-log-format)
    * [Configuring the log rotation](#configuring-the-log-rotation)
  * [Persistent Volumes](#persistent-volumes)
    * [Enabling Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB](#enabling-persistent-volumes-in-kafka-zookeeper-redis-and-couchdb)
    * [Deleting Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB](#deleting-persistent-volumes-in-kafka-zookeeper-redis-and-couchdb)
  * [Ingress activation](#ingress-activation)
  * [Healthcheck pod for Service Director ](#healthcheck-pod-for-service-director)
  * [Protecting Kubernetes Secrets ](#protecting-kubernetes-secrets)

## Introduction

This folder defines a Helm chart and repo for all deployment scenarios of HPE Service Director as service provisioner, Closed Loop or high availability. Deployment for Closed Loop nodes must include a Kubernetes cluster with Apache Kafka, an SNMP Adapter and a Service Director UI. Deployment of Service Director as service provisioner nodes must include a Kubernetes cluster with a Service Director UI.

The [/repo](../repo/) contains all the files of a Helm chart repository that houses an [index.yaml](../repo/index.yaml) file and the packaged charts.

The subfolder [/chart](./sd-helm-chart) contains the Helm chart files that contain:

- `values-production.yaml`: provides the data passed into the chart (for production environments)
- `values.yaml`: provides the data passed into the chart (for testing environments)
- `Chart.yaml`: contains your chart metainformation
- `/templates/`: contains SD deployment files
- `/templates/EFK/`: contains support files for the EFK example
- `/templates/prometheus/`: contains support files for the Prometheus example
- `/templates/redis/`: contains support files for the Redis deployment
- `/charts/`: contains additional Helm charts, needed as a dependency

## Deployment diagram

![sd-cloud-diagram](/kubernetes/docs/images/sd_containers.png)

**IMPORTANT:** The fact that all services shown in the above figure can be deployed using the HPE SD Helm chart does not imply that all services are provided by the HPE SD product. The “Backing services (HPE SD prerequisites)” are not provided by the HPE SD product and not supported by HPE.


## Prerequisites

The prerequisites for the Service Director Helm Chart deployment are a database and a namespace.

### 1. Database

**If you have already deployed a database, skip this step.**

Consider, as an example, an instance of the `postgres` image in a Kubernetes pod. It is a clean PostgreSQL 13 image with an `sa` user ready for Service Director installation.

You can find the DB connection setup parameters in the `values.yaml` file. The parameters description can be found [here](/kubernetes/helm/charts#common-parameters). For details on creating your own DB password, see [this description](/kubernetes/helm/charts#dbsecret).

**NOTE**: If you are not using the Kubernetes [postgres-db](../../templates/postgres-db) deployment, you need to overwrite the db parameter values defined in [values](./sd-helm-chart/values.yaml). They contain database-related environments and point to the installed database. Those values can be added to the deployment using the `-f` parameter in the `helm install` command.

The following databases are available:

- [postgres-db](/kubernetes/templates/postgres-db) directory.
- [enterprise-db](/kubernetes/templates/enterprise-db) directory.
- [oracle-db](/kubernetes/templates/oracle-db) directory.

**NOTE**: For production environments, use either an external, non-containerized database or create your own image. It can be based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).

### 2. Namespace

Before deploying HPE Service Director, you need to create a namespace with the name `sd`. To do so, run

```
kubectl create namespace sd
```

**NOTE**: Any existing namespace can be used for the helm deployment: `helm install --namespace <namespace>` command.

### 3. Resources

#### Resources in testing environments

Minimum requirements, for CPU and memory, are set by default in SD deployed pods.

**IMPORTANT:** Kubernetes worker nodes must be with at least 8 GB and 6 CPUs for SD pods to start without any problem. If any SD pod needs more resources, you get an error; for example, `FailedScheduling ... Insufficient cpu.`

| Resource         | Default Request Values   | Default Limit Values   |
| ---------------- | ------------------------ | ---------------------- |
| SD provisioner | 1 GB and 3 CPUs  | 3 GB and 5 CPUs      |
| SD UI          | 0.5 GB and 1 CPU | 3 GB and 3 CPUs      |

**NOTE**: The default values are set to achieve a minimum performance. Increase them according to your needs. The limit values can be too high if you are using testing environments such as Minikube. Change them accordingly.

You can find more information about tuning SD Helm chart resource parameters in the [Resources](../../docs/Resources.md) document.

*CouchDB*

The SD-UI pod needs a CouchDB instance to store session's data and work properly. This DB information must persist if a CouchDB pod restarts. Therefore, a persistent storage would be used via a PVC object that the CouchDB pod provides. The following parameters are available in the Helm chart during the installation of HPE SD:

- `couchdb.persistentVolume.storageClass`: name of the `storageClass` that provides the storage. If empty, the PVs available in the `storageClass` by default are used.
- `couchdb.persistentVolume.size`: the size of the PV to attach. It is 10 Gi by default. Check your HPE SD installation user guide for the recommended size.

**Note:** CouchDB can be backed up by taking a Volume Snapshot of its PVC following this [guide](../../docs/CouchDB_Backup.md). 

*Kafka/Zookeeper*

HPE Service Director Closed Loop can be configured to use Apache Kafka as an event collection framework. If it is enabled, it creates a pod for Kafka and a pod for Zookeeper ready to be used for HPE Service Director.

#### Resources in production environments

Minimum requirements, for CPU and memory, are set by default in SD deployed pods. It is recommended to adjust your Kubernetes production cluster using this [guide](../../docs/production%20deployment%20guidance.md).

| Resource         | Default Request Values   | Default Limit Values   |
| ---------------- | ------------------------ | ---------------------- |
| SD provisioner   | 2 GB and 3 CPUs          | 8 GB and 8 CPUs        |
| SD UI            | 0.5 GB and 1 CPU         | 4 GB and 4 CPUs        |

**Note**: The default values will achieve a minimum performance. Increase any value according to your needs.

You can find more information about tuning SD Helm chart resource parameters in the [Resources](/kubernetes/docs/Resources.md) document.

Persistent storage is activated in all SD pods, if needed, with a `storageclass`. For the cases the `storageClass` can be modified, check the Helm chart [values](./sd-helm-chart/values-production.yaml) file.

*CouchDB*

The SD-UI pod needs a CouchDB instance to store the session's data and work properly. This DB information must persist in case the CouchDB pod restarts. Therefore, a persistent storage would be used via a `storageclass`. A CouchDB cluster is created to be used for HPE Service Director as recommended. The installation creates, by default, three CouchDB pods and they are configured to run in different worker nodes to better tolerate node failures.

*Redis*

HPE Service Director UI relies on Redis as a notification system and session management framework. A Redis cluster is created to be used for HPE Service Director as recommended. The installation creates, by default, three Redis pods working as a master and two slaves. They are configured to run in different worker nodes to better tolerate node failures.

*Kafka/Zookeper*

HPE Service Director Closed Loop can be configured to use Apache Kafka as an event collection framework. If it is enabled, a Kafka and Zookeeper cluster is created to be used for HPE Service Director as recommended. The installation creates, by default, three pods for Kafka and another three for Zookeeper. They are configured to run in different worker nodes to better tolerate node failures.

*Kubernetes affinity/antiaffinity policies*

To better tolerate K8S node failures, it is recommended to apply some affinity and antiaffinity policies to your Provisioning and Closed Loop pods. Some affinity parameters are already included in the Helm chart and they are used to spread the pod instances between the nodes of the K8S cluster. It is recommended to review and modify them to comply with your affinity and antiaffinity policies.

| Parameter                     | Description                                   | Default                                                        |
| ------------------------------- | ----------------------------------------------- | ---------------------------------------------------------------- |
| `kafka.affinity`              | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread Kafka instances           |
| `kafka.zookeeper.affinity`    | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread Zookeeper instances       |
| `couchdb.affinity`            | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread CouchDB instances         |
| `redis.master.affinity`       | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread redis primary instances   |
| `redis.slave.affinity`        | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread redis secondary instances |
| `prometheus.grafana.affinity` | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread Grafana instances         |
| `efk.elastik.affinity`        | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread Elasticsearch instances   |
| `sdimage.affinity`            | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread provisioner instances     |
| `sdui_image.affinity`         | Use it to add affinity/antiaffinity policies. | `podAntiAffinity` rule set to spread SD-UI instances           |

### 4. Kubernetes version

Only Kubernetes version 1.18.0 or later is supported.

**NOTE**: With an older Kubernetes version, HPE SD components might not work as expected, or might not be able to deploy the Helm chart at all.

## Deploying Service Director

The deployment file uses [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), [LivenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [StartupProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to perform an application health check. This is to ensure the services have started in the right order, and to avoid  application initial restarts, until the prerequisites are fullfilled.

Before deploying the Helm Chart, if you are using an external database:

- adjust the `SDCONF_activator_db_`-prefixed environment variables as appropriate for the [test values](./sd-helm-chart/values.yaml) or [production values](./sd-helm-chart/values-production.yaml)
- make sure that your database is ready to accept connections

**IMPORTANT:** The [values.yaml](./sd-helm-chart/values.yaml) file defines the docker registry parameter for the used SD images. Specify this to point to the docker registry where your docker images are located (e.g.: `hub.docker.hpecorp.net/cms-sd`). For example,`- image: myrepository.com/cms-sd/sd-sp`.
If you need to mount your own Helm SD repository, you can use the files contained in the [repo](../repo/) folder, which contains the [index.yaml](../repo/index.yaml) file with the URL of the compressed ``tgz`` version of the Helm chart. You have to replace this URL with the URL of your local Helm repository.

**NOTE:** Regarding the amount of memory and disk space required for the Helm chart deployment, it is 4 GB RAM and minimum 25 GB free Disk on the assigned Kubernetes nodes running it. The amount of memory depends on other applications and pods running in the same node.

If the Kubernetes master and worker nodes are in the same host, like Minikube, a minimum of 16 GB RAM and 80 GB of disk space are required.

### Accessing SD Docker images from public DTR

It is possible to pull the SD Docker Images from the HPE public Docker Trusted Registry (DTR).

This requires an HPE Passport account and an access token to retrieve the SD images from the Public HPE DTR.

For the access token you need to make and validate an order via the HPE Software Center portal. You will receive an email notification with details and instructions on how to retrieve images using the token:

```
docker login -u <customer@company.com> hub.myenterpriselicense.hpe.com
Password: <access token>
Login succeeded
```

After login, the SD docker images can be pulled:

```
docker pull hub.myenterpriselicense.hpe.com/r2l74aae/sd-sp[:tag]
docker pull hub.myenterpriselicense.hpe.com/r2l74aae/sd-ui[:tag]
docker pull hub.myenterpriselicense.hpe.com/r2l74aae/sd-cl-adapter-snmp[:tag]
docker pull hub.myenterpriselicense.hpe.com/r2l74aae/sd-healthcheck[:tag]
```

Consult the [Release Notes](../../../../../releases) for information about image signature validation and release changes.

### Using a Service Director license

By default, a 30-day Instant On license is used. If you have a license file, provide it by creating a secret and bind-mounting it at `/license`, like this:

```
kubectl create secret generic sd-license-secret --from-file=license=<license-file> --namespace sd
```

Where `<license-file>` is the path to your HPE SD license file.

Specify the `sdimage.licenseEnabled` parameter using the `--set key=value[,key=value]` argument to `helm install`.

### Adding Secure Shell Key configuration for SD

It is possible to set SD-SP up to connect to target devices using a single common Secure Shell (SSH) private/public key pair. To enable this, a Kubernetes secret must be generated.

There is no SSH key pair provided by default.

1. Create the required SSH key pair using `ssh-keygen`.
2. Provide the private key to SD by creating a secret and bind-mounting it at `/ssh/identity`, as follows:

   ```
   kubectl create secret generic ssh-identity --from-file=identity=<identity-file> --namespace sd
   ```

   Where `<identity-file>` is the path to your SSH private key.
3. Specify the `sshEnabled` parameter by providing the `--set sdimage.sshEnabled=true` argument to `helm install`, to enable the SSH key use.

On target devices where this SSH connectivity is to be used, the corresponding public key must be appended to the users `~/.ssh/authorized_keys` file. This is a manual step.

### Using Service Account

When using a private Docker Registry, you need authentication. For authentication, a Service Account can be enabled. Perform the following steps to use the ServiceAccount feature:

1. Create a Secret with the registry credentials:

```
kubectl create secret docker-registry <secret-name> \
--docker-server=<registry> \
--docker-username=<username> --docker-password=<password> \
--docker-email=<email> \
--namespace sd
```

2. Set the `ServiceAccount` fields in your custom values file or in the `--set` parameters `helm install` command:

```
# values-file.yaml
serviceAccount:
  enabled: true
  create: true
  name: <service-account-name>
  imagePullSecrets:
  - name: <secret-name>
```

3. Run the `helm install` command setting the images' repository and version:

```
helm install sd-helm sd-chart-repo/sd_helm_chart \
--set sdimages.registry=<registry>,\
sdimages.tag=<image-version> \
--values <values-file.yaml> \
--namespace sd
```

### Adding Security Context configuration

A Security Context defines the privilege and access control settings for a Pod or a Container.

To specify the settings for the Pod, you have to enable the `SecurityContext` in the values file. The `securityContext` root field is used as a global and default value. You can specify for each deployment its own Security Context in the values file. Check this [table](#common-parameters) to see the description of the fields.

```
securityContext:
  enabled: false
  fsGroup: 1001
  runAsUser: 1001
```

### Deploying SD Closed Loop

To install an SD Closed Loop example with Helm, add the SD Helm repo:

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add couchdb https://apache.github.io/couchdb-helm
helm repo add sd-chart-repo https://raw.githubusercontent.com/HewlettPackard/hpe-sd-cloud/master/kubernetes/helm/repo/
```

- Test environment - to install a Service Director in a test environment, execute the following command:

  ```
  helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<registry> --namespace sd
  ```
- Production environment - to install a Service Director in a production environment, execute the following command:

  ```
  helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<registry> --namespace sd -f values-production.yaml
  ```

In the previous commands:

- `<registry>` is the Docker registry where the Service Director images are stored, usually this value is `hub.docker.hpecorp.net/cms-sd/`. If this parameter is omitted, the local repository is used by default.

**NOTE**: The SNMP adapter depends on Kafka.

- The SNMP adapter needs Kafka to get Assurance data, so in this case

  Always enable **both** of them. You can enable them by setting the parameters as follows:
  `kafka.enabled=true`
  `sdsnmp_adapter.enabled=true`

You can find additional information about production environments [here](../../docs/production%20deployment%20guidance.md).

The Kubernetes cluster now contains the following pods:

- `sd-cl`: HPE SD Closed Loop nodes, processing assurance and non-assurance requests - [sd-sp](/docker/images/sd-sp)
- `sd-ui`: UOC-based UI connected to HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-helm-couchdb`: CouchDB database
- `redis-master`: Redis database

The parameters chosen during the Helm chart start-up determine which pods are to be deployed.

The following services are also exposed to external ports in the Kubernetes cluster:

- `sd-cl`: Service Director Closed Loop node native UI
- `sd-cl-ui`: Unified OSS Console (UOC) for Service Director

To validate if the deployed SD-CL application is ready, execute the following command:

```
helm ls --namespace sd
```

As a result, the following chart must show a `DEPLOYED` status:

```
NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
sd-helm     1               Fri Apr 1 17:36:44 2022         DEPLOYED        sd_helm_chart-4.1.2     4.1.2           sd
```

When the SD-CL application is ready, the deployed services (SD User Interfaces) are exposed on the following URLs:

```
Service Director UI:
http://<cluster_ip>:<port>/login             (Service Director UI for Closed Loop nodes)
http://<cluster_ip>:<port>/activator/        (Service Director native UI)
```

**NOTE**: The Kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

**NOTE**: The service `port` can be found running the `kubectl get services --namespace sd` command.

To delete the Helm chart example, execute the following command:

```
helm uninstall sd-helm --namespace sd
```

#### Non-root deployment

When deploying the SD Closed Loop, the default SNMP adapter port is ``162``.

However, when running as a non-root user, the SNMP adapter is not able to listen on the default port ``162``. In this case, you need to set `SDCONF_asr_adapters_manager_port` to a non-privileged port (e.g. ``10162``), and then, if necessary, you can redirect the adapter to the public port ``162`` (``-p 162:10162/udp``). This is especially important when deploying to **OpenShift Container Platform (OCP)** .

### Deploying SD Provisioner

To install an SD provisioner example using Helm, add the SD Helm repos:

```
helm repo add couchdb https://apache.github.io/couchdb-helm
helm repo add sd-chart-repo https://raw.githubusercontent.com/HewlettPackard/hpe-sd-cloud/master/kubernetes/helm/repo/
```

To install Service Director, execute the following command:

```
helm install sd-helm sd-chart-repo/sd_helm_chart --set install_assurance=false,sdimages.registry=<registry> --namespace sd
```

To install Service Director in a production environment, execute the following command:

```
helm install sd-helm sd-chart-repo/sd_helm_chart --set install_assurance=false,sdimages.registry=<registry> --namespace sd -f values-production.yaml
```

In the previous commands:

- `<registry>` is the Docker repo where the Service Director image is stored, usually this value is `hub.docker.hpecorp.net/cms-sd/`. If this parameter is omitted, the local repo is used by default.

**NOTE:** You can find additional information about production environments [here](../../docs/production%20deployment%20guidance.md).

The [/repo](../repo) folder contains the Helm chart that deploys the following:

- `sd-sp`: HPE SD Provisioning node - [sd-sp](/docker/images/sd-sp)
- `sd-ui`: UOC-based UI connected to HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-helm-couchdb`: CouchDB database
- `redis-master`: Redis database

The parameters chosen during the Helm chart start-up determine which pods are to be deployed.

The following services are also exposed to external ports in the Kubernetes cluster:

- `sd-sp`: Service Director native UI
- `sd-ui`: Unified OSS Console (UOC) for Service Director

To validate if the deployed SD-SP applications are ready, execute the following command:

```
helm ls --namespace sd
```

The following chart must show a `DEPLOYED` status:

```
NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
sd-helm     1               Fri Apr 1   17:36:44 2022       DEPLOYED        sd_helm_chart-4.1.2     4.1.2           sd
```

When the SD application is ready, the deployed services (SD User Interfaces) are exposed on the following URLs:

```
Service Director UI:
http://<cluster_ip>:<port>/login             (Service Director UI)
http://<cluster_ip>:<port>/activator/        (Service Director provisioning native UI)
```

**NOTE:** The Kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

**NOTE:** The service `port` can be found running the `kubectl get services --namespace sd` command.

To delete the Helm chart example execute the following command:

```
helm uninstall sd-helm --namespace sd
```

### Exposing services

#### In testing environments

By default, in a testing environment, some `NodePort` type services are exposed externally using a random port. You can check the value of each port service using the following command:

```
kubectl get services --namespace sd
```

These services can be exposed externally on a fixed port specifying the port number on the `nodePort` parameter when you run the `helm install` command. You can see a complete service parameters list in [Service parameters](#service-parameters) section.

#### In production environments

In the production environment services are `CluterIP` type and they are not exposed externally by default.

### Customization

The following table lists common configurable chart parameters and their default values. See [values.yaml](./sd-helm-chart/values.yaml) for all available options.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

#### Global parameters

In case the SD Helm chart is used as dependency chart, global parameters can be helpful.
The following global parameters are supported.

| Parameter                   | Description                                                                                                                                                                       | Default |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `global.imageRegistry`      | Set to point to the Docker registry where SD and its subchart images (Redis, CouchDB, Kafka) are kept.                                                                            | null    |
| `global.storageClass`       | Define `storageclass` for full SD chart.                                                                                                                                          | null    |
| `global.sdimages.registry`  | Set to point to the Docker registry where SD images are kept.                                                                                                                     | null    |
| `global.sdimage.tag`        | Set to version of SD (sd-sp) image used during deployment.                                                                                                                        | null    |
| `global.prometheus.enabled` | Set to `true` to deploy Prometheus with SD, see [Enable metrics and display them in Prometheus and Grafana](#enable-metrics-and-display-them-in-prometheus-and-grafana).          | null    |
| `global.efk.enabled`        | Set to `true` to deploy ElasticSearch with SD, see [Display SD logs and analyze them in Elasticsearch and Kibana](#display-sd-logs-and-analyze-them-in-elasticsearch-and-kibana). | null    |
| `global.pullPolicy`         | Default `imagePullPolicy` for images that don't define any. This will not affect CouchDB, Kafka, and Redis images.                                                                | Always  |

**NOTE:** Globals will override any specific defined parameters (those described in the following table).

#### Common parameters

| Parameter                                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                          | Default                                                                                                                    |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `sdimages.registry`                            | Set to point to the Docker registry where SD images are kept                                                                                                                                                                                                                                                                                                                                                                         | Local registry (if using another registry, remember to add "`/`" at the end, for example `hub.docker.hpecorp.net/cms-sd/`) |
| `sdimages.tag`                                 | Set to version of SD images used during deployment                                                                                                                                                                                                                                                                                                                                                                                   | `4.1.2`                                                                                                                    |
| `sdimages.pullPolicy`                          | `PullPolicy` for SD images                                                                                                                                                                                                                                                                                                                                                                                                           | Always                                                                                                                     |
| `install_assurance`                            | Set it to `false` to disable Closed Loop                                                                                                                                                                                                                                                                                                                                                                                             | `true`                                                                                                                     |
| `secrets_as_volumes`                            | Passwords stored in secrets are mounted in the container's filesystem. Set it to `false` to pass them as env. variables.                                                                                                                                                                                                                                                                                                                                                                                            | `true`                                                                                                                     |
| `kafka.enabled`                                | Set it to `true` to enable Kafka                                                                                                                                                                                                                                                                                                                                                                                                     | `false`                                                                                                                    |
| `sdsnmp_adapter.enabled`                       | Set it to `true` to enable SNMP adapter                                                                                                                                                                                                                                                                                                                                                                                              | `false`                                                                                                                    |
| `monitoringNamespace`                          | Declares with which namespace Prometheus and EFK pods are deployed.                                                                                                                                                                                                                                                                                                                                                                  | `Namespace` provided for Helm deployment                                                                                   |
| `serviceAccount.enabled`                       | Enables Service Account usage                                                                                                                                                                                                                                                                                                                                                                                                        | `false`                                                                                                                    |
| `serviceAccount.create`                        | Creates a Service Account used to download Docker images from private Docker Registries                                                                                                                                                                                                                                                                                                                                              | `false`                                                                                                                    |
| `serviceAccount.name`                          | Sets the Service Account name                                                                                                                                                                                                                                                                                                                                                                                                        | null                                                                                                                       |
| `serviceAccount.imagePullSecrets.name`         | Sets the Secret name that contains the Docker Registry credentials                                                                                                                                                                                                                                                                                                                                                                   | null                                                                                                                       |
| `securityContext.enabled`                      | Enables the security settings that apply to all Containers in the Pod                                                                                                                                                                                                                                                                                                                                                                | `false`                                                                                                                    |
| `securityContext.fsGroup`                      | All the container processes are also part of that supplementary group ID                                                                                                                                                                                                                                                                                                                                                             | 0                                                                                                                          |
| `securityContext.runAsUser`                    | Specifies that for any Containers in the Pod, all processes run with that user ID                                                                                                                                                                                                                                                                                                                                                    | 0                                                                                                                          |
| `couchdb.enabled`                              | Set it to `false` to disable CouchDB                                                                                                                                                                                                                                                                                                                                                                                                 | `true`                                                                                                                     |
| `redis.enabled`                                | Set it to `false` to disable Redis                                                                                                                                                                                                                                                                                                                                                                                                   | `true`                                                                                                                     |
| `efk.enabled`                                  | Set it to `true` to deploy ElasticSearch, FluentD and Kibana with SD, see [Display SD logs and analyze them in Elasticsearch and Kibana](#display-sd-logs-and-analyze-them-in-elasticsearch-and-kibana)                                                                                                                                                                                                                              | `false`                                                                                                                    |
| `prometheus.enabled`                           | Set it to `true` to deploy Prometheus and Grafana with SD, see [Enable metrics and display them in Prometheus and Grafana](#enable-metrics-and-display-them-in-prometheus-and-grafana)                                                                                                                                                                                                                                               | `false`                                                                                                                    |
| **sdimage parameters**                         |                                                                                                                                                                                                                                                                                                                                                                                                                                      |                                                                                                                            |
| `sdimage.tag`                                  | Set to explicit version of SD-SP image used during deployment                                                                                                                                                                                                                                                                                                                                                                        |                                                                                                                      |
| `sdimage.licenseEnabled`                       | Set it to `true` to use a license file                                                                                                                                                                                                                                                                                                                                                                                               | `false`                                                                                                                    |
| `sdimage.sshEnabled`                           | Set it to `true` to enable Secure Shell (SSH) Key                                                                                                                                                                                                                                                                                                                                                                                    | `false`                                                                                                                    |
| `sdimage.metrics_proxy.enabled`                | Enables a proxy in port 9991 for metrics and health SD data URLs, that way you don't expose the SD API management in port 9990.                                                                                                                                                                                                                                                                                                      | `true`                                                                                                                     |
| `sdimage.metrics.enabled`                      | Enables the SD metrics and health data URLs, set it to `true`, if you want to use them without deploying the Prometheus example                                                                                                                                                                                                                                                                                                      | `false`                                                                                                                    |
| `enable_rolling_upgrade` | Set it to `true` to enable rolling upgrades                                                                                                                                                                                                                                                                                                                                                                                           | `false`                                                                                                                       |
| `sdimage.envSDCONF_install_om`                 | Set it to `yes` to enable deployment of the OM solution                                                                                                                                                                                                                                                                                                                                                                              | `no`                                                                                                                       |
| `sdimage.env.SDCONF_install_omtmfgw`           | Set it to `yes` to enable deployment of the OMTMFGW solution                                                                                                                                                                                                                                                                                                                                                                         | `no`                                                                                                                       |
| `sdimage.env.SDCONF_activator_db_vendor`       | Vendor or type of the database server used by HPE Service Activator. Supported values are Oracle, EnterpriseDB and PostgreSQL                                                                                                                                                                                                                                                                                                        | `PostgreSQL`                                                                                                               |
| `sdimage.env.SDCONF_activator_db_hostname`     | Hostname of the database server used by HPE Service Activator. If you are not using a K8s deployment, then you need to point to the used database. **Note:** Other Helm values can be referenced here using `{{ }}`. For example, a global `sdimage.env.SDCONF_activator_db_hostname` could be set and then referenced as: `sdimage.env.SDCONF_activator_db_hostname: {{ .Values.global.sdimage.env.SDCONF_activator_db_hostname }}` | `postgres-nodeport`                                                                                                        |
| `sdimage.env.SDCONF_activator_db_port`         | Port of the database server used by HPE Service Activator.                                                                                                                                                                                                                                                                                                                                                                           | null                                                                                                                       |
| `sdimage.env.SDCONF_activator_db_instance`     | Instance name for the database server used by HPE Service Activator                                                                                                                                                                                                                                                                                                                                                                  | sa                                                                                                                         |
| `sdimage.env.SDCONF_activator_db_user`         | Database username for HPE Service Activator to use                                                                                                                                                                                                                                                                                                                                                                                   | sa                                                                                                                         |
| `sdimage.env.SDCONF_activator_db_password`     | Password for the HPE Service Activator database user                                                                                                                                                                                                                                                                                                                                                                                 | secret                                                                                                                     |
| **sdui_image parameters**                      |                                                                                                                                                                                                                                                                                                                                                                                                                                      |                                                                                                                            |
| `sdui_image.env.SDCONF_install_omui`           | Set it to `yes` to enable the OM UI                                                                                                                                                                                                                                                                                                                                                                                                  | `no`                                                                                                                       |

There are **global** and **common** parameters to set the `tag` and the `registry`. The order of preference is:

For the `tag`:

1. `global.sdimage.tag` (only affects SD-SP/SD-CL, with a **global** scope)
2. Each StatefulSet or Deployment's `.image.tag` (for each case individually)
3. `sdimage.tag` (same as `1` but specific, if it's defined it would take preference over sdimages)
4. `sdimages.tag` (affects all SD pods, set by default in the Values)

For the `registry`:

1. `global.sdimages.registry`
2. `global.imageRegistry` (affects all SD images as well as all the dependencies that have an `imageRegistry` defined in their Values file, in the chart that would **exclude** CouchDB.)
3. Each StatefulSet or Deployment's `.image.registry` (for each case individually)
4. `sdimages.registry`

To summarize, this means that values precedence follow the hierachy as mentioned above: from top to bottom.

**Usage example:**

> Install this chart to get the `latest` SD-CL image tag, and SD-UI to use the `4.1.0` image explicit, tag by pulling these from the registry `hub.docker.hpecorp.net/cms-sd/` and pulling the SD-SNMP image from another registry `some.example.registry/cms-sd/`:

```
helm install sd-helm ./sd-helm-chart --set sdimages.registry=hub.docker.hpecorp.net/cms-sd/,sdimages.tag=latest,sdui_image.image.tag=4.1.0,deployment_sdsnmp.image.registry=some.example.registry/cms-sd/ --values ./sd-helm-chart/values.yaml --namespace sd
```

#### Service parameters

Service ports using a production configuration are not exposed by default. However, the following Helm chart parameters can be set to change the service type (`NodePort` or `LoadBalancer`). For some services that require access from the external network:


| Parameter                       | Description                       | Default production configuration value | Default testing configuration value |
| ------------------------------- | --------------------------------- | -------------------------------------- | ----------------------------------- |
| `prometheus.servicename`        | Sets Prometheus service name      | `null`                                 | `prometheus-service`                |
| `prometheus.serviceport`        | Sets Prometheus service port      | `null`                                 | `8080`                              |
| `prometheus.servicetype`        | Sets Prometheus service type      | `ClusterIP`                            | `NodePort`                          |
| `prometheus.nodePort`           | Sets Prometheus node port         | `null`                                 | `null`                              |
| `prometheus.grafanaservicetype` | Sets Grafana service type         | `ClusterIP`                            | `NodePort`                          |
| `prometheus.nodePort`           | Sets Grafana node port            | `null`                                 | `null`                              |
| `efk.servicetype`               | Sets EFK service type             | `ClusterIP`                            | `NodePort`                          |
| `efk.nodePort`                  | Sets EFK node port                | `null`                                 | `null`                              |
| `efk.kibana.servicetype`        | Sets Kibana service type          | `ClusterIP`                            | `NodePort`                          |
| `efk.kibana.nodePort`           | Sets Kibana node port             | `null`                                 | `null`                              |
| `service_sdsp.servicetype`      | Sets SD SP service type           | `ClusterIP`                            | `NodePort`                          |
| `service_sdsp.nodePort`         | Sets SD SP node port              | `null`                                 | `null`                              |
| `service_sdcl.servicetype`      | Sets SD CL service type           | `ClusterIP`                            | `NodePort`                          |
| `service_sdcl.nodePort`         | Sets SD CL node port              | `null`                                 | `null`                              |
| `service_sdui.servicetype`      | Sets SD UI service type           | `ClusterIP`                            | `NodePort`                          |
| `service_sdui.nodePort`         | Sets SD UI node port              | `null`                                 | `null`                              |
| `service_sdsnmp.servicetype`    | Sets SD SNMP adapter service type | `ClusterIP`                            | `NodePor`t                          |
| `service_sdsnmp.nodePort`       | Sets SD SNMP adapter node port    | `null`                                 | `null`                              |

If `NodePort` is set as the service-type value, you can also set a port number. Otherwise, a random port number is to be assigned.

##### ReplicaCount Parameters

| Parameter                                | Description                                                     | Default |
| ------------------------------------------ | ----------------------------------------------------------------- | --------- |
| `statefulset_sdsp.replicaCount`          | Set to`0` to disable Service provisioner nodes                  | `1`     |
| `statefulset_sdcl.replicaCount`          | Number of nodes processing assurance and non-assurance requests | `2`     |
| `statefulset_sdcl.replicaCount_asr_only` | Number of nodes processing only assurance requests              | `0`     |
| `sdui_image.replicaCount`                | Set to`0` to disable Service director UI                        | `1`     |
| `deployment_sdsnmp.replicaCount`         | Set to`0` to disable SNMP adapter                               | `1`     |

#### Resources parameters

| Parameter                           | Description                                                                                                         | Default  |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ---------- |
| `sdui_image.memoryrequested`        | Amount of memory a cluster node is requested when starting the UI container to start.                                   | `500Mi`  |
| `sdui_image.cpurequested`           | Amount of CPU a cluster node is requested when starting the UI container to start.                                      | `1`      |
| `sdui_image.memorylimit`            | Maximum amount of memory a cluster node will provide to the UI container.                                               | `3000Mi` |
| `sdui_image.cpulimit`               | Maximum amount of CPU a cluster node will provide to the UI container.                                                  | `3`      |
| `sdui_image.loadbalancer`           | Activates a load balancer for SD-UI/provisioner connections. Recommended for high availability scenarios.               | `false`  |
| `sdui_image.envoy_version`          | Docker image version (Bitnami) of the Envoy load balancer used for high availability SD-UI/provisioner connections.     | `1.16.4` |
| `deployment_sdsnmp.memoryrequested` | Amount of memory a cluster node is requested for the SNMP adapter container to start.                                   | `500Mi`  |
| `deployment_sdsnmp.cpurequested`    | Amount of CPU a cluster node is requested for the SNMP adapter container to start.                                      | `0.5`    |
| `deployment_sdsnmp.memorylimit`     | Maximum amount of memory a cluster node will provide to the SNMP adapter container.                                     | `2000Mi` |
| `deployment_sdsnmp.cpulimit`        | Maximum amount of CPU a cluster node will provide to the SNMP adapter container.                                        | `500Mi`  |

#### Image resources parameters

| Parameter                          | Description                                                                                                                   | Default  |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `sdimage.memoryrequested`          | Amount of memory a cluster node is requested when starting the Closed Loop or Provisioner container.                              | `500Mi  |
| `sdimage.cpurequested`             | Amount of CPU a cluster node is requested when starting the Closed Loop or Provisioner container.                                     | `1`     |
| `sdimage.memorylimit`              | Maximum amount of memory a cluster node will provide to the Closed Loop or Provisioner container.                                 | `3000Mi  |
| `sdimage.cpulimit`                 | Maximum amount of CPU a cluster node will provide to the Closed Loop or Provisioner container.                                    | `3`  |
| `fluentd.memoryrequested`          | Amount of memory a cluster node is requested when starting the Fluentd sidecar container.                                             | `512Mi` |
| `fluentd.cpurequested`             | Amount of CPU a cluster node is requested when starting the Fluentd sidecar container.                                                | `300m`  |
| `fluentd.memorylimit`              | Maximum amount of memory a cluster node will provide to the Fluentd sidecar container.                                            | `1Gi`   |
| `fluentd.cpulimit`                 | Maximum amount of memory a cluster node will provide to the Fluentd sidecar container.                                            | `500m`  |

#### Prometheus resources parameters

| Parameter                                | Description                                                                                                         | Default  |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- | -------- |
| `prometheus.grafana.memoryrequested`     | Amount of memory a cluster node is requested when starting Grafana container.                                       | `100Mi`  |
| `prometheus.grafana.cpurequested`        | Amount of CPU a cluster node is requested when starting Grafana container.                                          | `200m`   |
| `prometheus.grafana.memorylimit`         | Maximum amount of memory a cluster node will provide to the Grafana container.                                      | null     |
| `prometheus.grafana.cpulimit`            | Maximum amount of CPU a cluster node will provide to the Grafana container. No limit by default.                    | null     |
| `prometheus.ksm.memoryrequested`         | Amount of memory a cluster node is requested when starting the `kube-state-metrics` container.                      | `50Mi`   |
| `prometheus.ksm.cpurequested`            | Amount of CPU a cluster node is requested when starting the `kube-state-metrics` container.                         | `100m`   |
| `prometheus.ksm.memorylimit`             | Maximum amount of memory a cluster node will provide to the `kube-state-metrics` container. No limit by default.    | null     |
| `prometheus.ksm.cpulimit`                | Maximum amount of CPU a cluster node will provide to the `kube-state-metrics` container. No limit by default.       | null     |

#### Prometheus configuration parameters

| Parameter                                | Description                                                                                                         | Default  |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- | -------- |
| `prometheus.scrape_interval` | How frequently to scrape targets by default | `30`  |
| `prometheus.evaluation_interval` | How frequently to evaluate rules | `30`   |
| `prometheus.scrape_timeout` | How long until a scrape request times out | `25` |
#### EFK resources parameters

| Parameter                      | Description                                                                                                                                                                                | Default         |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------|
| `efk.elastic.memoryrequested`  | Amount of memory a cluster node is requested when starting Elasticsearch container.                                                                                                        | `1.3Gi`         |
| `efk.elastic.cpurequested`     | Amount of CPU a cluster node is requested when starting Elasticsearch container.                                                                                                           | `500m`          |
| `efk.elastic.memorylimit`      | Maximum amount of memory a cluster node will provide to the Elasticsearch container.                                                                                                       | `2Gi`           |
| `efk.elastic.cpulimit`         | Maximum amount of CPU a cluster node will provide to the Elasticsearch container.                                                                                                          | `1000m`         |
| `efk.elastic.esJavaOpts`       | Overrides the default heap size. For more information, check [this document](https://www.elastic.co/guide/en/elasticsearch/reference/master/advanced-configuration.html#set-jvm-heap-size) | `-Xmx1g -Xms1g` |
| `efk.kibana.memoryrequested`   | Amount of memory a cluster node is requested when starting Kibana container.                                                                                                               | `400Mi`         |
| `efk.kibana.cpurequested`      | Amount of CPU a cluster node is requested when starting Kibana container.                                                                                                                  | `300m`          |
| `efk.kibana.memorylimit`       | Maximum amount of memory a cluster node will provide to the Kibana container.                                                                                                              | `400Mi`         |
| `efk.kibana.cpulimit`          | Maximum amount of CPU a cluster node will provide to the Kibana container.                                                                                                                 | `1000m`         |

#### SD configuration parameters

You can use alternative values for some SD configuration parameters. You can use the following parameters in your `helm install`:

| Parameter                                                  | Description                                                                                                                                                                                                                               | Default |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| `SDCONF_asr_adapters_manager_port`                         | Used to overwrite SNMP adapter listen port (162 by default). A use case is when using rootless images, because non-root users cannot use port numbers below 1024.                                                                         | `null`  |
| `sdimage.env.SDCONF_activator_conf_jvm_max_memory`         |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_jvm_min_memory`         |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_activation_max_threads` |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_activation_min_threads` |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_defaultdb_max`     |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_defaultdb_min`     |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_inventorydb_max`   |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_inventorydb_min`   |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_mwfmdb_max`        |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_mwfmdb_min`        |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_resmgrdb_max`      |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_resmgrdb_min`      |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_servicedb_max`     |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_servicedb_min`     |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_uidb_max`          |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_pool_uidb_min`          |                                                                                                                                                                                                                                           |         |
| `sdimage.env.SDCONF_activator_conf_file_log_pattern`       | Sets the log pattern for HPE SA's Wildfly file output using [Wildfly's](https://github.com/wildfly/wildfly/blob/master/docs/src/main/asciidoc/_admin-guide/subsystem-configuration/Logging_Formatters.adoc#pattern-formatter) formatters. | `null`  |
| `sdimage.env.SDCONF_activator_conf_jboss_log_max_days`     | Maximum number of server.log old files that will be kept in disc. Each file is rotated daily. A value of `0` means no files will be deleted.  | `0` |
| `sdimage.env.SDCONF_activator_conf_resmgr_log_max_files`     | Maximum number of resmgr old log files that will be kept in disc. A value of `0` means no files will be deleted. | `0` |
| `sdimage.env.SDCONF_activator_conf_wfm_log_max_files`     |  Maximum number of mwfm old log files that will be kept in disc. A value of `0` means no files will be deleted.  | `0` |
| `sdui_image.env.SDCONF_sdui_log_format_pattern`            | Sets the log pattern for SD-UI using [Log4js](https://github.com/log4js-node/log4js-node/blob/master/docs/layouts.md#pattern-format) formatters.                                                                                          | `null`  |

#### Kafka and Zookeeper configuration parameters

You can use alternative values for some Kafka and Zookeeper configuration parameters. You can use the following parameters in your `helm install`:

| Parameter                                   | Description                                                                                | Default                                                             |
| --------------------------------------------- | ---------------------------------------------------------------------------------------- | --------------------------------------------------------------------|
| `kafka.replicacount`                        | Number of Kafka cluster nodes.                                                             | `3`                                                                 |
| `kafka.defaultReplicationFactor`            | Default replication factors for automatically created topics.                              | `3`                                                                 |
| `kafka.offsetsTopicReplicationFactor`       | The replication factor for the offsets topic.                                              | `3`                                                                 |
| `kafka.transactionStateLogMinIsr`           | The replication factor for the transaction topic.                                          | `3`                                                                 |
| `kafka.persistence.enabled`                 | Used to enable Kafka data persistence using `kafka.persistence.storageClass`.              | `true`                                                              |
| `kafka.persistence.storageClass`            | `storageClass` used for persistence.                                                       | `sdstorageclass`                                                    |
| `kafka.resources.requests.memory`            | Amount of memory a cluster node is requested when starting Kafka container.                | `256Mi`                                                             |
| `kafka.resources.requests.cpu`               | Amount of CPU a cluster node is requested when starting Kafka container.                   | `250m`                                                              |
| `kafka.resources.limits.memory`             | Maximum amount of memory a cluster node will provide to the Kafka containers.              | `1Gi`                                                               |
| `kafka.resources.limits.cpu`                | Maximum amount of CPU a cluster node will provide to the Kafka containers.                 | `400m`                                                              |
| `kafka.securityContext.enabled`             | Security context for the Kafka pods.                                                       | `false`                                                             |
| `kafka.securityContext.fsGroup`             | Folders `groupId` used in Kafka pods persistence storage.                                  | `1001`                                                              |
| `kafka.securityContext.runAsUser`           | `UserId` used in Kafka pods.                                                               | `1001`                                                              |
| `kafka.affinity`                            | Affinity/antiaffinity policy used                                                          | Distributes Kafka pods between all nodes in K8s cluster             |
| `kafka.metrics.kafka.enabled`               | enables kafka metrics exporter for prometheus and its grafana dashboard                    | false                                                               |
| `kafka.metrics.jmx.enabled`                 | enables jmx exporter for prometheus (mandatory if `kafka.metrics.kafka.enabled` is `true`) | false                                                               |
| `kafka.zookeeper.replicacount`              | Number of replicas for the Zookeeper cluster.                                              | `3`                                                                 |
| `kafka.zookeeper.persistence.enabled`       | Used to enable Zookeeper data persistence using `kafka.persistence.storageClass`.          | `true`                                                              |
| `kafka.zookeeper.persistence.storageClass`  | `storageClass` used for persistence.                                                       | `sdstorageclass`                                                    |
| `kafka.zookeeper.resources.requests.memory`  | Amount of memory a cluster node is requested when starting the Zookeeper container.        | `256Mi`                                                             |
| `kafka.zookeeper.resources.requests.cpu`     | Amount of CPU a cluster node is requested when starting Zookeeper containers.              | `250m`                                                              |
| `kafka.zookeeper.resources.limits.memory`   | Maximum amount of memory a cluster node will provide to the Zookeeper containers.          | `1Gi`                                                               |
| `kafka.zookeeper.resources.limits.cpu`      | Maximum amount of CPU a cluster node will provide to the Zookeeper containers.             | `400m`                                                              |
| `kafka.zookeeper.securityContext.enabled`   | Security context for the Zookeeper pods.                                                   | `false`                                                             |
| `kafka.zookeeper.securityContext.fsGroup`   | Folders `groupId` used in Zookeeper pods persistence storage.                              | `1001`                                                              |
| `kafka.zookeeper.securityContext.runAsUser` | `UserId` used in Zookeeper pods.                                                           | `1001`                                                              |
| `kafka.zookeeper.affinity`                  | Affinity/antiaffinity policy used.                                                         | Distributes Zookeeper pods between all nodes in Kubernetes cluster. |
| `kafka.zookeeper.metrics.enabled`           | enables ZooKeeper sidecar exporter for prometheus and it's grafana dashboard               | false                                                               |

- `Important`: The jmx exporter for kafka is **mandatory** in order to get the example dashboard working. JMX exporter translates the exposed metrics to a prometheus compliant format and the dashboard included reads the input from the existing prometheus job.

#### CouchDB configuration parameters

You can use alternative values for some CouchDB configuration parameters. You can use the following parameters in your `helm install`:

| Parameter                               | Description                                                                                                     | Default                                                          |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `couchdb.enabled`                       | Activates or deactivates the CouchDB deployment                                                                 | `true`                                                           |
| `couchdb.createAdminSecret`             | If enabled a Secret called <ReleaseName>-couchdb will be created containing auto-generated credentials          | `false`                                                          |
| `couchdb.clusterSize`                   | Number of nodes for the CouchDB cluster                                                                         | 3                                                                |
| `couchdb.persistentVolume.enabled`      | Activates or deactivates the CouchDB data persistence                                                           | `true`                                                           |
| `couchdb.persistentVolume.storageClass` | `Storageclass` used when persistence is enabled                                                                 | `sdstorageclass`                                                 |
| `couchdb.resources.requests.cpu`               | Amount of CPU a cluster node is requested when starting CouchDB container.                   | `100m`                                                              |
| `couchdb.resources.requests.memory`            | Amount of memory a cluster node is requested when starting CouchDB container.                | `256Mi`                                                             |
| `couchdb.resources.limits.cpu`                | Maximum amount of CPU a cluster node will provide to the CouchDB containers.                 | `400m`
| `couchdb.resources.limits.memory`             | Maximum amount of memory a cluster node will provide to the CouchDB containers.              | `1Gi`                                                               |
| `couchdb.couchdbConfig.couchdb.uuid`    | Unique identifier for this CouchDB server instance                                                              | `decafbaddecafbaddecafbaddecafbad`                               |
| `couchdb.initImage.pullPolicy`          | Pull policy for CouchDB `initImage`                                                                             | IfNotPresent                                                     |
| `couchdb.affinity`                      | affinity/antiaffinity policy used                                                                               | Distributes CouchDB pods between all nodes in Kubernetes cluster |
| `couchdb.dns.clusterDomainSuffix`       | This is used to generate FQDNs for peers when joining the CouchDB cluster                                       | cluster.local                                                    |

#### Redis configuration parameters

You can use alternative values for some Redis configuration parameters. You can use the following parameters in your `helm install`:

| Parameter                               | Description                                                                              | Default                                                            |
| ----------------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `redis.enabled`                         | Activates or deactivates the Redis deployment.                                           | `true`                                                             |
| `redis.cluster.enabled`                 | Enables Redis as a cluster with a primary/secondary structure.                           | `true`                                                             |
| `redis.cluster.slaveCount`              | Number of secondary nodes for the Redis cluster.                                         | `2`                                                                |
| `redis.redisPort`                       | Port used in Redis to receive incoming requests.                                         | `true`                                                             |
| `redis.existingSecret`                  | `Secret` that will be used to recover the Redis password.                                | `redis-password`                                                   |
| `redis.existingSecretPasswordKey`       | Link inside the `Secret` where the Redis password is stored.                             | `password`                                                         |
| `redis.metrics.enabled`                 | If enabled Redis metrics will be exposed to Prometheus example.                          | `false`                                                            |
| `redis.securityContext.enabled`         | Security context for the Redis pods.                                                     | `false`                                                            |
| `redis.securityContext.fsGroup`         | Folders `groupId` used in Redis pods persistence storage.                                | `1001`                                                             |
| `redis.securityContext.runAsUser`       | `UserId` used in Redis pods.                                                             | `1001`                                                             |
| `redis.master.persistence.enabled`      | Activates or deactivates the Redis master node data persistence.                         | `true`                                                             |
| `redis.master.persistence.storageClass` | `Storageclasss` used when persistence is enabled.                                        | `sdstorageclass`                                                   |
| `redis.master.resources.requests.memory` | Amount of memory a cluster node is requested when starting the Redis containers.         | `256 Mi`                                                           |
| `redis.master.resources.requests.cpu`    | Amount of memory a cluster node is requested when starting the Redis containers.         | `100 m`                                                            |
| `redis.master.affinity`                 | affinity/antiaffinity policy used                                                        | Distributes Redis master pods between all nodes in K8s cluster     |
| `redis.slave.persistence.enabled`       | Activates or deactivates the Redis secondary nodes data persistence.                     | `true`                                                             |
| `redis.slave.persistence.storageClass`  | `Storageclass` used when persistence is enabled.                                         | `sdstorageclass`                                                   |
| `redis.slave.resources.requests.memory`  | Amount of memory a cluster node is requested when starting the Redis containers.         | `256 Mi`                                                           |
| `redis.slave.resources.requests.cpu`     | Amount of memory a cluster node is requested when starting the Redis containers.         | `100 m`                                                            |
| `redis.slave.affinity`                  | affinity/antiaffinity policy used                                                        | Distributes Redis secondary pods between all nodes in K8s cluster. |
| `redis.metrics.enabled`                 | enable metrics endpoint for prometheus and it's grafana dashboard                        | false                                                              |

#### EFK configuration parameters

| Parameter                         | Description                                                                                                                                                                                    | Default |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `efk.elastic.extraVolumes`        | Additional volumes                                                                                                                                                                             | `null`  |
| `efk.elastic.extraVolumeMounts`   | Additional mount paths                                                                                                                                                                         | `null`  |
| `efk.elastic.extraInitContainers` | Extra `initContainers`                                                                                                                                                                         | `null`  |

#### Adding custom variables within a ConfigMap

In the previous sections, customizable parameters were specified in the [values.yaml](./sd-helm-chart/values.yaml) file. You can add more custom parameters within a `ConfigMap`. These are the steps for creating and using a `ConfigMap` to add your custom variables:

1. Create a `ConfigMap` with the desired variables.

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

**NOTE**: This can be done also by creating your own `values-custom.yaml` file and adding the parameters to it.

```
sdui_image:
    env_configmap_name: <config-map-name>
```

Then, point to this file when you run the `helm install` command:

```
helm install sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<repo>,sdimages.tag=<image-tag> --values ./sd-helm-chart/values-custom.yaml --namespace sd
```

#### Labeling pods and services

You can add extra labels to SD pods and the pods created in Prometheus and EFK scenarios, using the `podLabels` parameter. Labels are passed as a YAML **map**. For instance:

```
sdimage:
  podLabels:
    key1: value1
    key2: value2
    ...
```

You can add as many labels as needed.

These labels are particularly useful to cluster administrators as they allow to run commands like:

```
kubectl delete pod -l key1=value1 -n sd
```

This command deletes all the pods with the label `key1: value1` in the `sd` namespace.

##### Add more labels

There are label parameters in `sdimage`, `sdui_image` and `deployment_sdsnmp` to add labels to these pods **separately**. The labels in `efk` and `prometheus` would apply to **all** the pods instantiated in these scenarios. For example:

```
efk:
  labels:
    key1: value1
    key2: value2
```

Would add the label `key1: value1` to the Elasticsearch and Kibana pods.

##### Labeling services

For service labeling, you can use the `serviceLabels`, or specific `labels` parameters available for SD services in `sdimage`, `sdui_image` and `deployment_sdsnmp`.

The specific `serviceLabels` parameters can override those in each service's section of the values file. For instance, `service_sdui.labels` would override labels set with `sdui_image.serviceLabels`.

Labeling external third-party services is also supported through each service's `labels` parameter, such as `service_elf.labels` or `service_grafana.labels`.

The full list of supported specific service labels is as follows:

| Service                                                  | Values section                   |
| ---------------------------------------------------------- | ---------------------------------- |
| `sd-sp & headless-sd-sp`                                 | `service_sdsp.labels`            |
| `sd-cl & headless-sd-cl`                                 | `service_sdcl.labels`            |
| `sd-ui`                                                  | `service_sdui.labels`            |
| `sd-snmp-adapter`                                        | `service_sdsnmp.labels`          |
| `sd-sp-prometheus`                                       | `service_sdsp_prometheus.labels` |
| `sd-cl-prometheus`                                       | `service_sdcl_prometheus.labels` |
| `elasticsearch-service & elasticsearch-service-headless` | `service_efk.label`s             |
| `grafana & grafana-headless`                             | `service_grafana.labels`         |
| `sd-kube-state-metrics`                                  | `service_sd_ksm.labels`          |

For instance, you can add the labels `key1: value1` and `key2: value2` to the `sd-sp` service as follows:

```
service_sdsp
  labels:
    key1: value1
    key2: value2
```

#### Thirdparty registry options
| Paramerter | Description | Default |
|-----|-----|-----|
| `envoy.image.registry` | The specific registry for the envoy image. | `hub.docker.com/` |
| `envoy.image.name` | The name of the envoy image to use. | `bitnami/envoy` |
| `envoy.image.tag` | The specific version to pull from registry. | `1.16.5` |
| `fluentd.image.registry` | The specific registry for the fluentd image. | `hub.docker.com/` |
| `fluentd.image.name` | The name of the fluentd image to use. | `bitnami/fluentd` |
| `fluentd.image.tag` | The specific version to pull from registry. | `1.14.4` |
| `efk.image.registry` | The specific registry for the elasticsearch image. | `docker.elastic.co/` |
| `efk.image.name` | The name of the elasticsearch image to use. | `elasticsearch/elasticsearch` |
| `efk.image.tag` | The specific version to pull from registry. | `7.10.1` |
| `efk.kibana.image.registry` | The specific registry for the kibana image. | `docker.elastic.co/` |
| `efk.kibana.image.name` | The name of the kibana image to use. | `kibana/kibana` |
| `efk.kibana.image.tag` | The specific version to pull from registry. | `fallback to efk version` |
| `efk.elastalert.image.registry` | The specific registry for the elastalert image. | `hub.docker.com/` |
| `efk.elastalert.image.name` | The name of the elastalert image to use. | `bitsensor/elastalert` |
| `efk.elastalert.image.tag` | The specific version to pull from registry. | `2.0.1` |
| `prometheus.image.registry` | The specific registry for the prometheus image. | `hub.docker.com/` |
| `prometheus.image.name` | The name of the prometheus image to use. | `prom/prometheus` |
| `prometheus.image.tag` | The specific version to pull from registry. | `v2.33.5` |
| `prometheus.grafana.image.registry` | The specific registry for the grafana image. | `hub.docker.com/` |
| `prometheus.grafana.image.name` | The name of the grafana image to use. | `grafana/grafana` |
| `prometheus.grafana.image.tag` | The specific version to pull from registry. | `8.4.3` |
| `prometheus.ksm.image.registry` | The specific registry for the kube-state-metrics image. | `quay.io/` |
| `prometheus.ksm.image.name` | The name of the kube-state-metrics image to use. | `coreos/kube-state-metrics` |
| `prometheus.ksm.image.tag` | The specific version to pull from registry. | `v1.9.8` |

### Upgrading HPE Service Director Deployment

To upgrade the Helm chart, use the Helm `upgrade` command to apply the changes (for example, to change parameters):

```
helm upgrade sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<registry> --namespace sd
```

To upgrade Service Director in a production environment, execute the following command:

```
helm upgrade sd-helm sd-chart-repo/sd_helm_chart --set sdimages.registry=<registry> --namespace sd -f values-production.yaml
```

**IMPORTANT** : Make sure the solutions (adapters) version
you choose is actually supported by the chart release you are using. Older versions are tested against new chart releases.

### Uninstalling HPE Service Director Deployment

To uninstall the Helm chart execute the following command:

```
helm uninstall sd-helm --namespace=sd
```

## Service Director High Availability

When installing the SD Helm chart, you can increase the number of pods for the SD deployment. To do so, adjust the number of the replica count parameters when you perform the `helm install` or `helm upgrade`.

![SD-HA](/kubernetes/docs/images/SD-HA.png)

You can adjust the following replica counts for the pods in the Helm chart [ReplicaCount Parameters](#replicacount-parameters).

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

For an HA pod deployment, set each `replicacount` to at least `2`. For example:

```
--set statefulset_sdsp.replicaCount=2,sdui_image.replicaCount=2
```

Kubernetes ensures that the number of replicas is always the proper state of the running pods in the Helm deployment.

For more information about scaling best practices, see [this document](/kubernetes/docs/ScalingBestPractices.md).

## Enabling and displaying metrics in Prometheus and Grafana

**IMPORTANT:** Prometheus and Grafana are not part of the HPE SD product and are, therefore, not supported by HPE.

Prometheus and Grafana help you monitor any metric in your Kubernetes cluster. They can be deployed alongside "exporters" to expose cluster-level Kubernetes object metrics as well as machine-level metrics like CPU and memory usage.

This extra deployment can be activated during the `helm chart` execution using the following parameter:

```
prometheus.enabled=true
```

Two dashboards are preloaded in Grafana to display information about the SD pods performance in the cluster and Service Director's metrics.

This repo must be added using the following command:

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```

**NOTE:** Prometheus deploys in the default `namespace`, if there isn't any set in the `helm install` parameter. You can also use the parameter `monitoringNamespace` to set a customized namespace for Prometheus.

When Prometheus is enabled the Service Director pod will include a sidecar container called Fluentd that exposes SA alert metrics to Prometheus.

You can find more information about how to run the example and how to connect to Grafana and Prometheus [here](/kubernetes/docs/alertmanager).

By default, Redis, Kafka and ZooKeeper metrics are not included when enabling metrics. To enable them, the following parameter needs to be added to the `helm chart` execution:

```
redis.metrics.enabled=true
kafka.metrics.kafka.enabled=true,kafka.metrics.jmx.enabled=true
kafka.zookeeper.metrics.enabled=true
```

This also preload Redis, Kafka and Zookeeper example graphs in Grafana.
For further documentation about dashboards and metrics, please follow [this link](/kubernetes/docs/Grafana.md).

Some parts of the Prometheus example can be disabled to connect to another Prometheus or Grafana server that you already have in place. These are the extra parameters:

| Parameter                         | Description                                                                                                                                                                                                                                                                                                                                                                        | Default |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| `prometheus.server_enabled` | If set to `false`, the Prometheus and Grafana pods will not be deployed. Use the values in this [config](./sd-helm-chart/templates/prometheus/prometheus/configmap.yml) file to configure SD metrics to an alternative Prometheus server. Use these [dashboards](./sd-helm-chart/templates/prometheus/prometheus/grafana/)  to display SD metrics to an alternative Grafana server. | `true`  |
| `prometheus.alertmanager_enabled` | If set to `false`, the Alertmanager container will not be deployed in the Prometheus pod. You can find more information about the Alertmanager [here](/kubernetes/docs/alertmanager/README.md). | `false` |
| `prometheus.customJobs` | Allows to add custom Prometheus jobs | `[]` |
| `prometheus.extraContainers` | Additional containers. This value is evaluated as a template. Note: `VolumeMounts` for these extra containers can be defined as part of these container's definitions as well | `[]` |
| `prometheus.extraVolumes` | Extra volumes for the Prometheus container | `[]` |
| `prometheus.extraVolumeMounts` | Mount extra volume(s) to the Prometheus container. | `[]` |
| `prometheus.grafana.enabled` | If set to `false`, the Grafana pod will not be deployed. Use these [dashboards](./sd-helm-chart/templates/prometheus/prometheus/grafana/) to display SD metrics to an alternative Grafana server. | `true` |
| `prometheus.grafana.extraDashboardsConfigmaps` | Additional dashboards loaded from configmap's files. `name` is the name of the configmap, `dashboardFile` is used to configure the path where the dashboard will be mounted. Note: this must match the name given after `data` inside the configmap | `[]` |

### SD-Healthcheck pod metrics

The SD-Healthcheck pod includes a Prometheus compilant endpoint with multiple available metrics that are exposed in a prebuilt Grafana dashboard. This metrics show the full chart component status depending on the selected filter labels (see [healthcheck pod section](#healtheck-pod-for-service-director)). This endpoint and dashboard is available by specifying:

- `healthcheck.metrics.enabled=true`

You can see a preview of the prebuilt dashboard [here](/kubernetes/docs/Grafana.md/#sd-healthcheck_metrics)

### Additional metrics

For retrieving the metrics from SD you can access the Wildfly management API on port 9991 for `sd-sp` or `sd-cl` pods. It is activated when you deploy the Prometheus example. If you want to access these metrics without deploying the Prometheus example, you have to add two parameters during the `helm install` process:

`sdimage.metrics.enabled=true, sdimage.metrics_proxy.enable=true`

- `sdimage.metrics.enabled` enables the SD metrics and health data URLs
- `sdimage.metrics_proxy.enabled` enables a proxy in port 9991 for metrics and health SD data URLs. That way you don't expose the full Wildfly management API.

Setting `sdimage.metrics_proxy.enabled` to `true` or deploying the Prometheus example will add an extra Envoy sidecar container to avoid the full Wildfly management API exposure. That way only the URL for the metrics needed is exposed [here](http://sd-sp:9991/metrics) or [here](http://sd-cl:9991/metrics).

### Troubleshooting

- Issue: System-related metrics (for example, *CPU usage*) have not been retrieved.
- Solution: Install the Kubernetes metrics server. The Installation guide can be found [here](https://hewlettpackard.github.io/Docker-Synergy/blog/install-metrics-server.html).

## Displaying and analyzing SD logs in Elasticsearch and Kibana

The EFK Stack helps by providing us with a powerful platform that

**IMPORTANT:** Elsticsearch and Kibana are not part of HPE SD product and not supported by HPE.


- collects and processes data from multiple SD logs,
- stores logs in one centralized scalable data store,
- provides a set of tools to analyze those logs.

This extra deployment can be activated during the `helm chart` execution using the following parameter:

```
efk.enabled=true
```

Several Kibana indexes are preloaded in Kibana to display logs of Service Activator's activity.

**NOTE:** EFK deploys in the default `namespace`, if there isn't any set in the `helm install` parameter. You can also use the parameter `monitoringNamespace` to set a customized namespace for EFK.

Elasticsearch requires the `vm.max_map_count` to be at least 262144; therefore, before EFK deployment check whether your OS sets this number up to a higher value.

The following logs are available to Elasticsearch and Kibana:

- Wildfly server logs as `wildfly-yyyy.mm.dd`
- Server log from UOC as `uoc-yyyy.mm.dd`
- Service Activator workflow manager logs as `sa_mwfm-yyyy.mm.dd`
- HPE SA resource manager logs as `sa_resmgr-yyyy.mm.dd`
- Redis messages `redis-input-YYYY.MM.dd`

Fluentd is used to collect the logs and send them to the Elasticsearch pod. If you want to use your own fluentd instance, you have to set the parameter `efk.fluentd.enabled=false` during `helm install` execution.

The following SD log information is read by Fluentd:

- `SD container`: Wildfly log using the following path - `/opt/HP/jboss/standalone/log/`
- `SD container`: Service Director log using the following path - `/var/opt/OV/ServiceActivator/log/`
- `SD container`: SNMP adapter log using the following path - `/opt/sd-asr/adapter/log/`
- `SD UI container`: UOC log using the following path - `/var/opt//uoc2/logs`

You can check whether the SD logs indexes were created and stored in Elasticsearch using the Kibana web interface, you can find more information [here](../../docs/Kibana.md).

Raising SD alerts with EFK is optional in the SD Helm chart and it is not activated by default. For the additional setup and more find information [here](../../docs/elastalert/README.md).

Some parts of the EFK example can be disabled to connect to another Elasticsearch or fluentd that you already have in place. These are the extra parameters:

| Parameter | Description | Default |
|-----|-----|-----|
| `efk.enabled` |  If set to false the EFK pods won't deploy | `false` |
| `efk.elastalert.enabled` |  If set to false the Elastalert pod won't deploy. Use the parameter `efk.elastalert.efkserver` to point to an alternative Elasticsearch server | `false` |
| `efk.fluentd.enabled` |  If set to false the Fluentd pod won't deploy | `true` |
| `efk.elastic.enabled` |  If set to false the Kibana and Elasticsearch pods will not deploy. Use the parameter `efk.fluentd.elasticserver` to point to an alternate server| `true` |
| `efk.kibana.enabled` | If set to false the Kibana pod will no deploy. Use elasticsearch exposed service to connect to an alternate Kibana server to the EFK pod | `true` |

### Gathering logs for CouchDB, Kafka, Zookeeper and Redis

Some SD pods send their logs to the ``stdout`` and can be captured by reading the ``/var/lib/docker/containers`` folder from the Kubernetes nodes. The pods sending their logs to ``stdout`` are CouchDB, Kafka, Zookeeper and Redis.

If you are using Openshift as your platform to deploy the SD helm chart, you can use the log capabilities it offers. OpenShift administrators can deploy cluster logging using a CLI commands and the OpenShift Container Platform web console to install the Elasticsearch Operator and Cluster Logging Operator. When the operators are installed, you can create a Cluster Logging Custom Resource (CR) to schedule cluster logging pods and other resources necessary to support cluster logging. The operators are responsible for deploying, upgrading, and maintaining cluster logging.

OpenShift uses Fluentd to collect data about your cluster, it is deployed as a DaemonSet in OpenShift Container Platform that deploys pods to each OpenShift Container Platform node.
To make changes to your cluster logging deployment, create and modify a Cluster Logging Custom Resource (CR) [More info here](https://docs.openshift.com/container-platform/4.1/logging/config/efk-logging-fluentd.html).

### Configuring the log format
SD-SP log format can be configured directly from the Helm chart with the parameter `sdimage.env.SDCONF_activator_conf_file_log_pattern` using Wildfly's logging [formatters](https://github.com/wildfly/wildfly/blob/master/docs/src/main/asciidoc/_admin-guide/subsystem-configuration/Logging_Formatters.adoc).

The same can be done with SD-UI using a similar parameter `sdui_image.env.SDCONF_sdui_log_format_pattern`, in this case using log4js formatters, although they are pretty similar to Wildfly's, there could be differences. To learn more about log4js formatters, click [here](https://github.com/log4js-node/log4js-node/blob/master/docs/layouts.md#pattern-format)

### Configuring the log rotation

Rotation for all three SD-SP logs can be configured with `sdimage.env.SDCONF_activator_conf_jboss_log_max_days` for `server.log` files, `sdimage.env.SDCONF_activator_conf_resmgr_log_max_files` for `resmgr.xml` files, and `sdimage.env.SDCONF_activator_conf_wfm_log_max_files` for `mwfm.xml` files. 

Check [SD configuration parameters](#sd-configuration-parameters) for more info regarding these parameters.

## Persistent Volumes

### Enabling Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB

A Persistent Volume (PV) is a cluster resource that you can use to store data for a pod and it persists beyond the lifetime of that pod. The PV is backed by a networked storage system such as NFS.

Redis, Kafka/Zookeeper and CouchDB come with data persistance disabled by default. To enable a PV, you have to start the Helm chart with the following parameters:

```
kafka.persistence.enabled=true
kafka.zookeeper.persistence.enabled=true
couchdb.persistentVolume.enabled=true
redis.master.persistence.enabled=true
```

Therefore, the following command must be executed to install Service Director (Closed Loop example):

```
helm install sd-helm sd-chart-repo/sd_helm_chart --set kafka.persistence.enabled=true,kafka.zookeeper.persistence.enabled=true,couchdb.persistentVolume.enabled=true,redis.master.persistence.enabled=true,sdimages.registry=<registry> --namespace sd
```

Before this step, some PVs must be generated in the Kubernetes cluster. Some Kubernetes distributions such as Minikube or MicroK8S create the PVs for you. Therefore, the storage persistence needed for Kafka, Zookeeper, Redis, CouchDB or database pods are automatically handled. You can read more information [here](/kubernetes/docs/PersistentVolumes.md#persistent-volumes-in-single-node-configurations).

If you have configured dynamic provisioning on your cluster, such that all storage claims are dynamically provisioned using a storage class, as described [here](/kubernetes/docs/PersistentVolumes.md#persistent-volumes-in-multi-node-configurations), you can skip the following steps.

If you have not configured dynamic provisioning on your cluster, you need to create this and a default storage class manually, as described [here](/kubernetes/docs/PersistentVolumes.md#local-volumes-in-k8s-nodes).

### Deleting Persistent Volumes in Kafka, Zookeeper, Redis and CouchDB

Deleting the Helm release does not delete the Persistent Volume Claims (PVC) that were created by the dependencies packages in the SD Helm chart. This behavior allows you to deploy the chart again with the same release name and keep your Kafka, Zookeeper and CouchDB data. If you want to delete everything, you must delete the PVCs manually. To delete every PVC, issue the following commands:

```
kubectl delete pvc data-kafka-service-0
kubectl delete pvc data-zookeeper-service-0
kubectl delete pvc data-redis-master-0
kubectl delete pvc database-storage-sd-helm-couchdb-0
```

## Ingress activation

Ingress is a Kubernetes-native way to implement the virtual hosting pattern, a mechanism to host many HTTP sites on a single IP address. Typically, you use an Ingress for decoding and directing incoming connections to the right Kubernetes service's app. Ingress can be set up in Service Director deployment to include one or several host names to target the native UI and UOC UI.

If you have an Ingress controller already configured in your cluster, this extra deployment can be activated during the Helm chart execution using the following parameter:

```
ingress.enabled=true
```

The following table lists common configurable chart parameters and their default values. See [values.yaml](./sd-helm-chart/values.yaml) for all the available options.

| Parameter                      | Description                                                                                                                                                                                                                                                                                               | Default |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| `ingress.enabled`              | Enable Ingress controller resource.                                                                                                                                                                                                                                                                       | `false` |
| `ingress.annotations`          | Ingress annotations done as `key:value` pairs, see [annotations](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/annotations.mdl) for a full list of possible Ingress annotations.                                                                            | `[]`    |
| `ingress.hosts`                | The value `ingress.host` will contain the list of hostnames to be covered with this Ingress record. These hostnames must be previously set up in your DNS system. The value is an array in case more than one hosts are needed. The following parameters are for the first host defined in your Ingress.  | `array` |
| `ingress.hosts[0].name`        | Hostname to your service director installation.                                                                                                                                                                                                                                                           | `null`  |
| `ingress.hosts[0].sdenabled`   | Set to `true` to enable a Service-Director-native UI path on the Ingress record. Each SD-enabled host will map the Service-Director-native UI requests to the `/sd` path.                                                                                                                                 | `true`  |
| `ingress.hosts[0].sduienabled` | Set to `true` to enable a Service Director Unified OSS Console (UOC) path on the Ingress record. Each SD-UI-enabled host will map the Service Director UOC UI requests to the `/sdui` path.                                                                                                               | `true`  |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

The following command is an example of an installation of Service Director with Ingress enabled:

```
helm install sd-helm sd-chart-repo/sd_helm_chart --set ingress.enabled=true,,ingress.hosts[0].name=sd.native.ui.com,ingress.hosts[0].sdenabled=true,ingress.hosts[0].sduienabled=false,ingress.hosts[1].name=sd.uoc.ui.com,ingress.hosts[1].sdenabled=false,ingress.hosts[1].sduienabled=true --namespace sd
```

The Ingress configuration sets up two different hosts:

- one for Service-Director-native UI at:

```
http://sd.native.ui.com/sd
```

- and one for Service Director Unified OSS Console (UOC) at:

  ```
  http://sd.uoc.ui.com/sdui
  ```

Another example of installation of Service Director with Ingress enabled, with a single host with no name, using your cluster IP address:

```
helm install sd-helm sd-chart-repo/sd_helm_chart --set ingress.enabled=true --namespace sd
```

The Ingress configuration sets up two different hosts;

- one for Service-Director-native UI at:

  ```
  http://xxx.xxx.xxx.xxx/sd
  ```
- and a Service Director Unified OSS Console (UOC) at:

  ```
  http://xxx.xxx.xxx.xxx/sdui
  ```

where `xxx.xxx.xxx.xxx` is your cluster IP address.

**NOTE:** As guidance, an example of how to deploy an NGINX Ingress is provided:

In a bare metal Kubernetes cluster:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml
```

If you want to use a Helm chart:

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginxingress ingress-nginx/ingress-nginx
```

To enable the NGINX Ingress controller in Minikube, run the following command:

```
minikube addons enable ingress
```

## dbsecret

You can find a default DB password in [the secret object](/kubernetes/helm/charts/sd-helm-chart/templates/secret.yaml). If you are in a production environment the `dbpasssword` value is different and you have to point to a new one inside a new secret object. To overwrite the DB password you just deploy the following secret before the SD deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dbsecret
type: Opaque
data:
  dbpassword: xxxxxx
```

where `xxxxxx` is your DB password in base64 format. To activate it during the deployment you have to include the parameter `sdimage.env.SDCONF_activator_db_password_name=dbsecret` in your `helm install` command.

## Healthcheck pod for Service Director

To manage containers effectively, the user needs to check the SD deployment's health, that is, whether the pods started, whether they work correctly, and so on. SD deployment uses a healthcheck pod to determine whether the SD app instances are running and responding.

Because the separate components work independently, each part keeps running even after other components have failed. Therefore, a global status view is needed at some point to ensure the SD still provides its functionality.

There can be cases where a pod might still be in the initialization stage, not yet ready to receive and process requests, but at the same time it is not needed for the core functionality. In that case the healthstatus pod reports that incident, but still reports SD as active.

### Control healthcheck with rules

To decide if the SD deployment is `healthy`, some rules must be applied in the healthcheck pod. The values file from the SD Helm chart contains a `healthcheck.labelfilter` parameter as the following:

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

Healthcheck monitors the pods with labels included in `healthcheck.labelfilter.unhealthy` and `healthcheck.labelfilter.degraded` parameters.

The values `unhealthy` and `degraded` follow these rules:

1. Healthcheck returns a `healthy` healthStatus response based on the following:

   - Any of each deployment/statefulset labeled as `unhealthy` has all its instances up and running.
2. Healthcheck returns a `degraded` healthStatus response based on the following:

   - Any of each deployment/statefulset labeled as `unhealthy` has some of its instances not up and running, or
   - Any of each deployment/statefulset labeled as `degraded` has all its instances not up and running.
3. Healthcheck returns an `unhealthy` healthStatus response  based on the following:

   - Any of each deployment/statefulset labeled as `unhealthy` has all of its instances not up and running.

### Healthcheck interface and output

The healthcheck exposes an API in port 8080 in the healthcheck pod. The response is `200 OK`, unless there is an internal error in the process. The data returned is in *.json* format.

The healthcheck pod exposes the port 8080 internally. To access the healthcheck from outside the cluster, we can make use of the sd-healthcheck service:

```
http://yourclusterip:xxxxx/healthcheck
```

where `xxxxx` is the NodePort.

The *.json* output contains a `healthStatus` key with the values `healthy`, `degraded` or `unhealthy` as described previously. It also contains an `application` key with a description of the status of all the pods monitored by the `healthcheck.labelfilter` parameter.
The returned code is `200 OK`.

```
{
  "name": "sd",
  "healthStatus": "unhealthy",
  "description": "HPE Service director app health status",
  "capabilities": [
    {
      "pod": [
        {
          "containersReady": "1/1",
          "containerRestarts": 0,
          "name": "redis-master-0",
          "status": "Running"
        }
      ],
      "replicas": 1,
      "name": "redis-master",
      "healthStatus": "healthy",
      "podStatus": {
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
          "containersReady": "2/2",
          "containerRestarts": 0,
          "name": "sd-ui-0",
          "status": "Running"
        },
        {
          "containersReady": "1/2",
          "containersRestarts": 0,
          "name": "sd-ui-1",
          "status": "Running"
        }
      ],
      "replicas": 2,
      "name": "sd-ui",
      "healthStatus": "healthy",
      "podStatus": {
        "running": 2,
        "waiting": 0,
        "failed": 0,
        "succeeded": 0
      },
      "type": "statefulset"
    },
  .....
```

In case of an error during the API request, you get a `400 HTTP` code with a *.json* response. The response contains a key called `error` with a description pointing to a `healthcheck` container log file.

### Deploying healthcheck with the SD Helm chart

Healthcheck pod comes as optional in SD Helm chart. You can deploy it using the parameter `healthcheck.enabled=true` during the `helm install` phase.

As in OpenShift deployments, a Service Account is required to give the permissions to run the pod. If this is your case, then you have to enable it using the parameter `healthcheck.serviceaccount.enabled=true`.

If you want to use an already created Service Account, you can overwrite the parameter `healthcheck.serviceaccount.name` with your own value. Otherwise a Service Account called `sd-healthcheck` is created and a `Role` and `RoleBinding` object is used.

### Healthcheck parameters

| Parameter                               | Description                                                                                                                                                           | Default          |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| `healthcheck.enabled`                   | If set to `false`, the pod won't deploy.                                                                                                                              | `false`          |
| `healthcheck.tag`                       | Set to the version of the SD Healthcheck image for deployment.                                                                                                         | `1.0.6`          |
| `healthcheck.registry`                  | Set to point to the Docker registry, where the healthcheck image is kept. In case it's  set to null, the default registry is the SD image one.                        | `null`           |
| `healthcheck.name`                      | Name of the container's image.                                                                                                                                        | `sd-healthcheck` |
| `healthcheck.labelfilter.unhealthy`     | List of pods to monitor with the `unhealthy` rule.                                                                                                                    | `list of pods`   |
| `healthcheck.labelfilter.degraded`      | List of pods to monitor with the `degraded` rule.                                                                                                                     | `list of pod`s   |
| `healthcheck.resources.requests.memory` | Amount of memory a cluster node is requested when starting the container.                                                                                             | `256Mi`          |
| `healthcheck.resources.requests.cpu`    | Amount of CPU a cluster node is requested when starting the container.                                                                                                | `250m`           |
| `healthcheck.resources.limits.memory`   | Maximum amount of memory a cluster node will provide to the container.                                                                                                | `500Mi`          |
| `healthcheck.resources.limits.cpu`      | Maximum amount of CPU a cluster node will provide to the container.                                                                                                   | `400m`           |
| `healthcheck.securityContext.runAsUser` | `UserId` used in healthcheck pods, if `securityContext.enabled` is set to `true`.                                                                                     | `1001`           |
| `healthcheck.securityContext.fsGroup`   | `groupId` folders used in pods persistence storage, if `securityContext.enabled` is set to `true`.                                                                    | `1001`           |
| `healthcheck.serviceaccount.enabled`    | If enabled, a Security Account will be added to the pod.                                                                                                              | `false`          |
| `healthcheck.serviceaccount.name`       | Name of the Security Account assigned to the pod (must exist in the cluster). If set to`sd-healthcheck`, a Role and a Security Account will be generated for the pod. | `sd-healthcheck` |
| `healthcheck.env.log_level`       | Used to set the log4j2 log level for the healthcheck pod, possible levels are: OFF, FATAL, ERROR, WARN, INFO, DEBUG, TRACE, ALL. | `INFO` |
| `healthcheck.templateOutput.enabled`       | If set to  True an external [Jinja]( https://palletsprojects.com/p/jinja/) template file, with the name template.config, will be used to render the response output instead of the template defined in response_configmap.yaml | `false` |
| `healthcheck.livenessProbe.failureThreshold`       | Number of times the probe is taken before restarting the pod. | `2` |
| `healthcheck.livenessProbe.initialDelaySeconds`       | Initial delay in seconds for the probe to take place. | `30` |
| `healthcheck.livenessProbe.periodSeconds`       | Time in between probes. | `5` |
| `healthcheck.readinessProbe.failureThreshold`       | Number of times the probe is taken before restarting the pod. | `2` |
| `healthcheck.readinessProbe.periodSeconds`       | Time in between probes. | `5` |
| `healthcheck.startupProbe.failureThreshold`       | Number of times the probe is taken before restarting the pod. | `6` |
| `healthcheck.startupProbe.periodSeconds`       | Time in between probes. | `10` |
| `healthcheck.metrics.enabled`       | If true, the Prometheus job for sd-healthcheck will be enabled and a Grafana dashboard will be available. | `false` |


### Protecting Kubernetes Secrets

Kubernetes can either mount secrets in the file system from the pods that use them, or save them as environment variables. You can control the behaviour of secrets used to store SD passwords using the parameter `secrets_as_volumes` that it is included in the values.yaml file. By default this parameter is set to true and those password will be stored as files inside the containers.

Secrets injected as environment variables into the configuration of the container are less secure and are also visible to anyone that has access to inspect the containers. Kubernetes secrets exposed by environment variables may be able to be enumerated on the host via /proc/. The parameter is included in case you want set it as false to use env. variables in a testing environment.

.

