# HPE Service Activator Helm chart Deployment

## Contents

* [HPE Service Activator Helm chart Deployment](#hpe-service-activator-helm-chart-deployment)
  * [Introduction](#introduction)
  * [Prerequisites](#prerequisites)
    * [1. Database](#1-database)
    * [2. Namespace](#2-namespace)
    * [3. Resources](#3-resources)
      * [Resources in testing environments](#resources-in-testing-environments)
      * [Resources in production environments](#resources-in-production-environments)
    * [4. Kubernetes version](#4-kubernetes-version)
  * [Deploying HPE Service Activator](#deploying-hpe-service-activator)
    * [Accessing the HPE SA Helm Chart and Docker images from public DTR](#accessing-hpe-sa-helm-chart-and-docker-images-from-public-dtr)
    * [Using an HPE Service Activator license](#using-an-hpe-service-activator-license)
    * [Adding Secure Shell (SSH) Key configuration for HPE SA](#adding-secure-shell-key-configuration-for-hpe-sa)
    * [Using a Service Account](#using-a-service-account)
    * [Adding Security Context configuration](#adding-security-context-configuration)
    * [Deployment](#deployment)
    * [Exposing services](#exposing-services)
      * [In testing environments](#in-testing-environments)
      * [In production environments](#in-production-environments)
    * [Customization](#customization)
      * [Common parameters](#common-parameters)
      * [Service parameters](#service-parameters)
        * [ReplicaCount Parameters](#replicacount-parameters)
      * [Resources parameters](#resources-parameters)
      * [HPE SA configuration parameters](#sa-configuration-parameters)
      * [Adding custom variables within a ConfigMap](#adding-custom-variables-within-a-configmap)
      * [Labeling pods and services](#labeling-pods-and-services)
      * [Third-party registry options](#third-party-registry-options)
    * [Upgrading HPE Service Activator Deployment](#upgrading-hpe-service-activator-deployment)
    * [Uninstalling HPE Service Activator Deployment](#uninstalling-hpe-service-activator-deployment)
  * [HPE Service Activator High Availability](#hpe-service-activator-high-availability)
  * [Enabling metrics](#enabling-metrics)
  * [Logging](#logging)
    * [Configuring the log format](#configuring-the-log-format)
    * [Configuring the log rotation](#configuring-the-log-rotation)
    * [Serving logs](#serving-logs)
  * [dbsecret](#dbsecret)
    * [Protecting Kubernetes Secrets ](#protecting-kubernetes-secrets)


 


## Introduction

This folder defines a Helm chart for the deployment of HPE Service Activator.

This folder contains the Helm chart files that contain:

- `values-production.yaml`: provides the data passed into the chart (for production environments)
- `values.yaml`: provides the data passed into the chart (for testing environments)
- `Chart.yaml`: contains your chart metainformation
- `/templates/`: contains HPE SA deployment files


## Prerequisites

The prerequisites for the HPE Service Activator Helm Chart deployment are a database and a namespace.


### 1. Database

**If you have already deployed a database, skip this step.**

Consider, as an example, an instance of the `postgres` image in a Kubernetes pod. It is a clean PostgreSQL 13 image with an `sa` user ready for the HPE Service Activator installation. 

You can find the DB connection setup parameters in the `values.yaml` file. The parameters description can be found [here](/kubernetes/helm/charts#common-parameters). For details on creating your own DB password, see [this description](/kubernetes/helm/charts#dbsecret).

**NOTE**: If you are not using the Kubernetes [postgres-db](/kubernetes/templates/postgres-db) deployment, you need to overwrite the DB parameter values defined in [values](./sa-helm-chart/values.yaml). They contain database-related environments and point to the installed database. Those values can be added to the deployment using the `-f` parameter in the `helm install` command.

The following databases are available:

- [postgres-db](/kubernetes/templates/postgres-db) directory.
- [enterprise-db](/kubernetes/templates/enterprise-db) directory.
- [oracle-db](/kubernetes/templates/oracle-db) directory.

**IMPORTANT** Have in mind that these examples are meant to be used with HPE SD and must be adapted for HPE SA. In the case of PostgreSQL, the namespace in the `postgresdb-deployment.yaml` file must be changed from `sd` to `sa`.

**NOTE**: For production environments, use either an external, non-containerized database or create your own image. It can be based on the official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).

### 2. Namespace

Before deploying the HPE Service Activator Helm chart, you need to create a namespace. In this guide, the namespace `sa` is used. To do so, run

```
kubectl create namespace sa
```

**NOTE**: Any existing namespace can be used for Helm deployment: `helm install --namespace <namespace>` command.

### 3. Resources

#### Resources in testing environments

Minimum requirements for CPU and memory are set by default in HPE SA deployed pods.

**IMPORTANT:** Kubernetes worker nodes must have at least 8 GB and 6 CPUs for HPE SA pods to start without any problem. If any HPE SA pod needs more resources, you get an error such as `FailedScheduling ... Insufficient cpu.`

| Resource         | Default Request Values   | Default Limit Values   |
| ---------------- | ------------------------ | ---------------------- |
| SA | 1 GB and 3 CPUs  | 3 GB and 5 CPUs      |

**NOTE**: The default values are set to achieve a minimum performance. Increase them according to your needs. The limit values can be too high if you are using testing environments such as Minikube. Change them accordingly.

#### Resources in production environments

Minimum requirements, for CPU and memory, are set by default in HPE SA deployed pods.

| Resource         | Default Request Values   | Default Limit Values   |
| ---------------- | ------------------------ | ---------------------- |
| SA   | 2 GB and 3 CPUs          | 8 GB and 8 CPUs        |

**Note**: The default values will achieve a minimum performance. Increase any value according to your needs.

### 4. Kubernetes version

Only Kubernetes version 1.18.0 or later is supported.

**NOTE**: With an older Kubernetes version, HPE SA components might not work as expected, or might not be able to deploy the Helm chart at all.

## Deploying HPE Service Activator

The deployment file uses [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), [LivenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [StartupProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to perform an application health check. This is to ensure the services have started in the right order, and to avoid application initial restarts until the prerequisites are fulfilled.

Before deploying the Helm Chart, if you are using an external database:

- adjust the `activator_db_`-prefixed environment variables as appropriate for the [test values](./values.yaml) or [production values](./values-production.yaml)
- make sure that your database is ready to accept connections

**IMPORTANT:** The [values.yaml](./values.yaml) file defines the Docker registry parameter for the used HPE SA images. Specify this to point to the Docker registry where your Docker images are located (e.g.: `hub.docker.hpecorp.net/cms-sd`). For example,`- image: myrepository.com/cms-sd/sa`.

**NOTE:** Regarding the amount of memory and disk space required for the Helm chart deployment, it is 4 GB RAM and minimum 25 GB free Disk on the assigned Kubernetes nodes running it. The amount of memory depends on other applications and pods running in the same node.

If the Kubernetes master and worker nodes are in the same host, like Minikube, a minimum of 16 GB RAM and 80 GB of disk space are required.

### Accessing HPE SA Helm Chart and Docker images from public DTR

It is possible to pull the HPE SA Helm chart and the HPE SA Docker Images from the HPE public Docker Trusted Registry (DTR).

This requires an HPE Passport account and an access token to retrieve the HPE SA Helm chart and HPE SA images from the Public HPE DTR.

For the access token, you need to make and validate an order via the HPE Software Center portal. You will receive an email notification with details and instructions on how to retrieve the images and the helm chart using the token:

**HPE SA Helm Chart**

Note that in Helm version 3.8.x or later, it is required to do a `helm pull` from the DTR:

```

helm registry login hub.myenterpriselicense.hpe.com --username <customer@company.com> --password <access token>
Password: <access token>
Login succeeded
```

After login, the HPE SA Helm chart can be pulled:

```
helm pull oci://hub.myenterpriselicense.hpe.com/cms/<SKU_Number>/sa-helm-chart --version <tag>
```

**HPE SA Images**

```
docker login -u <customer@company.com> hub.myenterpriselicense.hpe.com
Password: <access token>
Login succeeded
```

After login, the HPE SA Docker images can be pulled with the following command:

```
docker pull hub.myenterpriselicense.hpe.com/<SKU_Number>/sa[:tag]
```

Consult the [Release Notes](../../../../../releases) for information about image signature validation and release changes.

### Using an HPE Service Activator license

By default, a 30-day Instant On license is used. If you have a license file, provide it by creating a secret and bind-mounting it at `/license`, as follows:

```
kubectl create secret generic sa-license-secret --from-file=license=<license-file> --namespace sa
```

where `<license-file>` is the path to your HPE SA license file.

Specify the `sa.licenseEnabled` parameter using the `--set key=value[,key=value]` argument to `helm install`.

### Adding Secure Shell Key configuration for HPE SA

It is possible to set HPE SA up to connect to target devices using a single common Secure Shell (SSH) private/public key pair. To enable this, a Kubernetes secret must be generated.

There is no SSH key pair provided by default.

Complete the following steps to add SSH key configuration:

1. Create the required SSH key pair using `ssh-keygen`.
2. Provide the private key to HPE SA by creating a secret and bind-mounting it at `/ssh/identity`, as follows:

   ```
   kubectl create secret generic ssh-identity --from-file=identity=<identity-file> --namespace sa
   ```

   Where `<identity-file>` is the path to your SSH private key.
3. Specify the `sshEnabled` parameter by providing the `--set sa.sshEnabled=true` argument to `helm install`, to enable the SSH key use.

On the target devices where the SSH connectivity is to be used, the corresponding public key must be appended to the users `~/.ssh/authorized_keys` file. This is a manual step.

### Using a Service Account

When using a private Docker Registry, you need authentication. For authentication, a Service Account can be enabled. Perform the following steps to use the ServiceAccount feature:

1. Create a Secret with the registry credentials:

    ```
    kubectl create secret docker-registry <secret-name> \
    --docker-server=<registry> \
    --docker-username=<username> --docker-password=<password> \
    --docker-email=<email> \
    --namespace sa
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
    helm install sa-helm sa-helm-chart-<sa-version>.tgz \
    --set sa.image.registry=<registry>,\
    sa.image.tag=<image-version> \
    --values <values-file.yaml> \
    --namespace sa
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

### Deployment

To install HPE Service Activator, complete the following steps: 

1. Download the HPE SA Helm chart as described in section [Accessing the HPE SA Helm Chart and Docker images from public DTR](#accessing-sa-helm-chart-and-docker-images-from-public-dtr).

2. Do one of the following:

   * Test environment - to install an HPE Service Activator instance in a test environment, execute the following command:

      ```
      helm install sa-helm sa-helm-chart-<sa-version>.tgz --set sa.image.registry=<registry> --namespace sa
      ```

   * Production environment - to install an HPE Service Activator instance in a production environment, execute the following command:

      ```
      helm install sa-helm sa-helm-chart-<sa-version>.tgz --set sa.image.registry=<registry> --namespace sa -f values-production.yaml
      ```

In the previous commands:

- `<registry>` is the Docker repo where the Service Activator image is stored, usually this value is `hub.docker.hpecorp.net/cms-sd/`. If this parameter is omitted, the local repository is used by default.

**NOTE:** You can find additional information about requirements in the *HPE Service Activator Installation Guide*. Note that the requirements listed in the Guide represent the bare minimum and a production installation must be configured depending on the solutions that will run under HPE Service Activator.


The following services are also exposed to external ports in the Kubernetes cluster:

- `sa`: HPE Service Activator UI

To validate if the deployed HPE SA applications are ready, execute the following command:

```
helm ls --namespace sa
```

The following chart must show a `DEPLOYED` status:

```
NAME        REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
sa-helm     1               Tue Nov 29    17:36:44 2022     DEPLOYED        sa-helm-chart-9.1.13    9.1.13          sa
```

When the HPE SA application is ready, the deployed services (HPE SA User Interfaces) are exposed on the following URLs:

```
Service Activator UI:
http://<cluster_ip>:<port>/activator/        (Service Activator provisioning native UI)
```

**NOTE:** The Kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

**NOTE:** The service `port` can be found running the `kubectl get services --namespace sa` command.

To delete the Helm chart example, execute the following command:

```
helm uninstall sa-helm --namespace sa
```

### Exposing services

#### In testing environments

By default, in a testing environment, some `NodePort` type services are exposed externally using a random port. You can check the value of each port service using the following command:

```
kubectl get services --namespace sa
```

These services can be exposed externally on a fixed port specifying the port number on the `nodePort` parameter when you run the `helm install` command. You can see a complete service parameters list in [Service parameters](#service-parameters) section.

#### In production environments

In a production environment, services are `CluterIP` type and they are not exposed externally by default.


### Customization

The following table lists common configurable chart parameters and their default values. See the [values.yaml](./values.yaml) file for all available options.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.


#### Common parameters

| Parameter                                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                          | Default                                                                                                                    |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `sa.image.registry`                            | Set to point to the Docker registry where HPE SA images are kept                                                                                                                                                                                                                                                                                                                                                                     | Local registry (if using another registry, remember to add "`/`" at the end, for example `hub.docker.hpecorp.net/cms-sd/`) |
| `sa.image.tag`                                 | Set to version of HPE SA images used during deployment                                                                                                                                                                                                                                                                                                                                                                               | `9.1.13`                                                                                                                   |
| `sa.image.pullPolicy`                          | `PullPolicy` for HPE SA image                                                                                                                                                                                                                                                                                                                                                                                                        | Always                                                                                                                     |
| `sa.image.tag`                                 | Set to explicit version of HPE SA image used during deployment                                                                                                                                                                                                                                                                                                                                                                       |                                                                                                                            |
| `secrets_as_volumes`                           | Passwords stored in secrets are mounted in the container's filesystem. Set it to `false` to pass them as environment variables.                                                                                                                                                                                                                                                                                                      | `true`                                                                                                                     |
| `serviceAccount.enabled`                       | Enables Service Account usage                                                                                                                                                                                                                                                                                                                                                                                                        | `false`                                                                                                                    |
| `serviceAccount.create`                        | Creates a Service Account used to download Docker images from private Docker Registries                                                                                                                                                                                                                                                                                                                                              | `false`                                                                                                                    |
| `serviceAccount.name`                          | Sets the Service Account name                                                                                                                                                                                                                                                                                                                                                                                                        | null                                                                                                                       |
| `serviceAccount.imagePullSecrets.name`         | Sets the Secret name that contains the Docker Registry credentials                                                                                                                                                                                                                                                                                                                                                                   | null                                                                                                                       |
| `securityContext.enabled`                      | Enables the security settings that apply to all Containers in the Pod                                                                                                                                                                                                                                                                                                                                                                | `false`                                                                                                                    |
| `securityContext.fsGroup`                      | All the container processes are also part of that supplementary group ID                                                                                                                                                                                                                                                                                                                                                             | 0                                                                                                                          |
| `securityContext.runAsUser`                    | Specifies that for any Containers in the Pod, all processes run with that user ID                                                                                                                                                                                                                                                                                                                                                    | 0                                                                                                                          |
| `sa.licenseEnabled`                            | Set it to `true` to use a license file                                                                                                                                                                                                                                                                                                                                                                                               | `false`                                                                                                                    |
| `sa.sshEnabled`                                | Set it to `true` to enable Secure Shell (SSH) Key                                                                                                                                                                                                                                                                                                                                                                                    | `false`                                                                                                                    |
| `sa.env.activator_db_vendor`                   | Vendor or type of the database server used by HPE Service Activator. Supported values are Oracle, EnterpriseDB and PostgreSQL                                                                                                                                                                                                                                                                                                        | `PostgreSQL`                                                                                                               |
| `sa.env.activator_db_hostname`                 | Hostname of the database server used by HPE Service Activator. If you are not using a K8s deployment, then you need to point to the used database. **Note:** Other Helm values can be referenced here using `{{ }}`. For example, a global `sa.env.activator_db_hostname` could be set and then referenced as: `sa.env.activator_db_hostname: {{ .Values.global.sa.env.activator_db_hostname }}` | `postgres-nodeport`               |                                                                                                                            |
| `sa.env.activator_db_port`                     | Port of the database server used by HPE Service Activator.                                                                                                                                                                                                                                                                                                                                                                           | null                                                                                                                       |
| `sa.env.activator_db_instance`                 | Instance name for the database server used by HPE Service Activator                                                                                                                                                                                                                                                                                                                                                                  | sa                                                                                                                         |
| `sa.env.activator_db_user`                     | Database username for HPE Service Activator to use                                                                                                                                                                                                                                                                                                                                                                                   | sa                                                                                                                         |
| `sa.env.activator_db_password`                 | Password for the HPE Service Activator database user                                                                                                                                                                                                                                                                                                                                                                                 | secret                                                                                                                     |
| `sa.env.rolling_upgrade`                       | Set it to `true` to enable rolling upgrades                                                                                                                                                                                                                                                                                                                                                                                          | false                                                                                                                      |
| `sa.metrics.enabled`                           | Set it to `true` to enable metrics and health data URLs                                                                                                                                                                                                                                                                                                                                                                              | false                                                                                                                      |
| `sa.metrics.proxy.enabled`                     | Set it to `true` to enable an Envoy proxy in port `9991` for metrics and health HPE SA data URLs. This way the HPE SA API management in port `9990` is not exposed.                                                                                                                                                                                                                                                                  | false                                                                                                                      |
 
#### Service parameters

Service ports using a production configuration are not exposed by default. However, the following Helm chart parameters can be set to change the service type (`NodePort` or `LoadBalancer`). For some services that require access from the external network:



| Parameter                       | Description                       | Default production configuration value | Default testing configuration value |
| ------------------------------- | --------------------------------- | -------------------------------------- | ----------------------------------- |
| `service_sa.servicetype`        |  Sets HPE SA service type         | `ClusterIP`                            | `NodePort`                          |
| `service_sa.nodePort`           |  Sets HPE SA node port            | `null`                                 | `null`                              |
| `service_envoy.servicetype`     |  Sets Envoy service type          | `ClusterIP`                            | `NodePort`                          |
| `service_envoy.nodePort`        |  Sets Envoy node port             | `null`                                 | `null`                              |

If `NodePort` is set as the service-type value, you can also set a port number. Otherwise, a random port number is to be assigned.


#### ReplicaCount Parameters

| Parameter                                | Description                                                     | Default |
| ---------------------------------------- | --------------------------------------------------------------- | ------- |
| `statefulset_sa.replicaCount`            | Set to `0` to disable HPE Service Activator nodes               | `1`     |


#### Resources parameters

| Parameter                           | Description                                                                                              | Default    |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------- | ---------- |
| `sa.memoryrequested`          | Amount of memory a cluster node is requested when starting the HPE Service Activator container.                | `500Mi     |
| `sa.cpurequested`             | Amount of CPU a cluster node is requested when starting the HPE Service Activator container.                   | `1`        |
| `sa.memorylimit`              | Maximum amount of memory a cluster node will provide to the HPE Service Activator container.                   | `3000Mi    |
| `sa.cpulimit`                 | Maximum amount of CPU a cluster node will provide to the HPE Service Activator container.                      | `3`        |


#### HPE SA configuration parameters

You can use alternative values for some HPE SA configuration parameters. You can use the following parameters in your `helm install`:

| Parameter                                                  | Description                                                                                                                                                                                                                               | Default |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| `sa.env.activator_conf_jvm_max_memory`         |                                                                                                                                                                                                                                                       |         |
| `sa.env.activator_conf_jvm_min_memory`         |                                                                                                                                                                                                                                                       |         |



#### Third-party registry options
| Paramerter               | Description                                   | Default           |
|--------------------------|-----------------------------------------------|-------------------|
| `envoy.image.registry`   | The specific registry for the Envoy image.    | `hub.docker.com/` |
| `envoy.image.name`       | The name of the Envoy image to use.           | `bitnami/envoy`   |
| `envoy.image.tag`        | The specific version to pull from registry.   | `1.16.5`          |
| `envoy.image.pullPolicy` | `imagePullPolicy` for the Envoy image.        | `Always`          |



#### Adding custom variables within a ConfigMap

In the previous sections, customizable parameters were specified in the [values.yaml](./values.yaml) file. You can add more custom parameters within a `ConfigMap`. These are the steps for creating and using a `ConfigMap` to add your custom variables:

1. Create a `ConfigMap` with the desired variables.

    ```
    ---
    apiVersion: v1
    kind: ConfigMap
    metadata:
        name: <config-map-name>
        namespace: sa
    data:
        SACONF_activator_conf_activation_max_threads: 50
    ```

   **Note** The `data` section will hold the extra environment parameters. In the case of an Ansible parameter, it has to be named like `SACONF_<parameter_name>`. A list of the possible Ansible parameters can be found under the *Ansible Installation* section of the *HPE Service Activator Installation Guide*.


2. Do one of the following: 

   * Run the `helm install` command and set the ConfigMap name using the `--set` parameter:

      ```
      helm install sa-helm sa-helm-chart-<sa-version>.tgz --set sa.image.registry=<repo>,sa.image.tag=<image-tag>,sa.env_config_map=<configmap-name> --namespace sa
      ```

   * Or create your own `values-custom.yaml` file and add the parameters to it.

      ```
      sa:
        env_configmap_name: <config-map-name>
      ```

     Then, point to this file when you run the `helm install` command:

      ```
      helm install sa-helm sa-helm-chart-<sa-version>.tgz --set sa.image.registry=<repo>,sa.image.tag=<image-tag> --values ./values-custom.yaml --namespace sa
      ```

#### Labeling pods and services

You can add extra labels to the HPE SA pod using the `podLabels` parameter. Labels are passed as a YAML **map**. Consider the following example:

```
sa:
  podLabels:
    key1: value1
    key2: value2
    ...
```

You can add as many labels as needed.

These labels are particularly useful to cluster administrators as they allow running commands like:

```
kubectl delete pod -l key1=value1 -n sa
```

This command deletes all the pods with the label `key1: value1` in the `sa` namespace.

##### Labeling services

For service labeling, you can use the `serviceLabels`, or specific `labels` parameters available for HPE SA services in `sa`.

The specific `serviceLabels` parameters can override those in each service's section of the values file. For instance, `service_sa.labels` would override labels set with `sa.serviceLabels`.

The full list of supported specific service labels is as follows:

| Service                               | Values section                     |
| ------------------------------------- | ---------------------------------- |
| `sa`                                  | `service_sa.labels`                |
| `sa-envoy`                            | `service_envoy.labels`             |


For instance, you can add the labels `key1: value1` and `key2: value2` to the `sa` service as follows:

```
service_sa
  labels:
    key1: value1
    key2: value2
```

### Upgrading HPE Service Activator Deployment

To upgrade the HPE SA Helm chart, use the Helm `upgrade` command to apply the changes (for example, to change parameters):

```
helm upgrade sa-helm sa-helm-chart-<sa-version>.tgz --set sa.image.registry=<registry> --namespace sa
```

To upgrade HPE Service Activator in a production environment, execute the following command:

```
helm upgrade sa-helm sa-helm-chart-<sa-version>.tgz --set sa.image.registry=<registry> --namespace sa -f values-production.yaml
```

**IMPORTANT** : Make sure the solutions (adapters) version you choose is actually supported by the chart release you are using. Older versions are tested against new chart releases.


### Uninstalling HPE Service Activator Deployment

To uninstall the HPE SA Helm chart, execute the following command:

```
helm uninstall sa-helm --namespace=sa
```


## HPE Service Activator High Availability

When installing the HPE SA Helm chart, you can increase the number of pods for the HPE SA deployment. To do so, adjust the number of the replica count parameters when you perform `helm install` or `helm upgrade`.

You can adjust the following replica counts for the pods in the Helm chart [ReplicaCount Parameters](#replicacount-parameters).

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

For an HA pod deployment, set each `replicacount` to at least `2`. For example:

```
--set statefulset_sa.replicaCount=2
```

Kubernetes ensures that the number of replicas is always the proper state of the running pods in the Helm deployment.

For more information about scaling best practices, see [this document](/kubernetes/docs/ScalingBestPractices.md).


## Enabling metrics

HPE Service Activator can be configured to enable Prometheus-compatible metrics. This allows integration with Prometheus and Grafana to monitor HPE Service Activator.

**NOTE:** Prometheus and Grafana deployments are not provided by the SA helm chart at the moment.
**IMPORTANT:** Prometheus and Grafana are not part of the HPE SD product and are, therefore, not supported by HPE.

Metrics can be enabled using the following parameter:

```
sa.metrics.enabled=true
```

Service Activator exposes metrics under the administrator port (`9990` by default). Exposing this port might be a security issue in some cases. This can be avoided by using a sidecar container to act as a proxy for the metrics that will be exposed in the `9991` port. How this port is exposed can be configured by modifying the `service_envoy` service. 

To enable this behavior, the following parameter must be set:

```
sa.metrics.proxy.enabled=true
```

Envoy will be used as the proxy for this matter. For more information on Envoy, see the [official website](https://www.envoyproxy.io/).


## Logging

### Configuring the log format

HPE SA log format can be configured using the parameter `SACONF_activator_conf_file_log_pattern`, which uses Wildfly's logging [formatters](https://github.com/wildfly/wildfly/blob/master/docs/src/main/asciidoc/_admin-guide/subsystem-configuration/Logging_Formatters.adoc).

**Note** Information regarding how to add custom parameters can be found in the [Adding custom variables within a ConfigMap](#adding-custom-variables-within-a-configmap) section. 

### Configuring the log rotation

Rotation for all three HPE SA logs can be configured using the parameters `SACONF_activator_conf_jboss_log_max_days` for `server.log` files, `SACONF_activator_conf_resmgr_log_max_files` for `resmgr.xml` files, and `SACONF_activator_conf_wfm_log_max_files` for `mwfm.xml` files. 

**Note** Information regarding how to add custom parameters can be found in the [Adding custom variables within a ConfigMap](#adding-custom-variables-within-a-configmap) section. 

### Serving logs

HPE Service Activator produces logs in different entry points and formats, which is not ideal when processing them. To ease access to logs, a serving logs option is provided. It can be configured in the following way:


| Paramerter                 | Description                                       | Default           |
|----------------------------|---------------------------------------------------|-------------------|
| `sa.severLogs.enabled`     | `true` to enable the serving logs feature         | `false`           |
| `sa.severLogs.source.type` | Aggregation method to fetch HPE SA logs           | `fluentd`         |
| `sa.severLogs.target.type` | Indicates how the logs are served by the source   | `stdout`          |


#### Source values

Source refers to the method used to aggregate HPE SA logs. The following values are supported:

| Source type       | Description                                                      |
|-------------------|------------------------------------------------------------------|
| `fluentd`         | A fluentd sidecar container will be added to the HPE SA pods     |

##### Fluentd source

When `fluentd` is selected, its image needs to be configured with the following parameters:

| Paramerter                   | Description                                                                           | Default                 |
|------------------------------|---------------------------------------------------------------------------------------|-------------------------|
| `fluentd.image.registry`     | Docker repo where the fluentd image is stored                                         | ``                      |
| `fluentd.image.name`         | Docker image name of fluentd                                                          | `bitnami/fluentd`       |
| `fluentd.image.tag`          | Docker image tag of fluentd                                                           | `1.14.4-debian-10-r32`  |
| `fluentd.image.pullPolicy`   | `imagePullPolicy` for the fluentd image                                               | `Always`                |
| `fluentd.memoryrequested`    | Amount of memory a cluster node is requested when starting the fluentd container      | `512Mi`                 |
| `fluentd.cpurequested`       | Amount of CPU a cluster node is requested when starting the fluentd container         | `300m`                  |
| `fluentd.memorylimit`        | Maximum amount of memory a cluster node will provide to the fluentd container         | `1Gi`                   |
| `fluentd.cpulimit`           | Maximum amount of CPU a cluster node will provide to the fluentd container            | `500m`                  |

#### Target values

Target refers to the method used to serve the logs by the source. Valid targets depend on the selected source type. The following values are supported:


| Target type       | Description                                                                     | Source constraints |
|-------------------|---------------------------------------------------------------------------------|--------------------|
| `stdout`          | HPE SA logs will be outputted by the standard output of the fluentd container   | `fluentd`          |
| `elasticsearch`   | HPE SA logs will be sent to an external Elasticsearch server                    | `fluentd`          |


##### Elasticsearch target

No Elasticsearch server is deployed, so an external server needs to be used. It can be configured with the following parameters:

| Paramerter                          | Description                                | Default                 |
|-------------------------------------|--------------------------------------------|-------------------------|
| `sa.severLogs.target.type.host`     | Host of the Elasticsearch server           | ``                      |
| `sa.severLogs.target.type.port`     | Port of the Elasticsearch server           | ``                      |


## dbsecret

You can find a default DB password in [the secret object](./templates/secret.yaml). If you are in a production environment the `dbpasssword` value is different and you have to point to a new one inside a new secret object. To overwrite the DB password, deploy the following secret before the HPE SA deployment:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dbsecret
type: Opaque
data:
  dbpassword: xxxxxx
```

where `xxxxxx` is your DB password in `base64` format. To activate it during the deployment, include the parameter `sa.env.db_password_name=dbsecret` in your `helm install` command.


### Protecting Kubernetes Secrets

Kubernetes can either mount secrets in the file system from the pods that use them, or save them as environment variables. You can control the behavior of secrets used to store HPE SA passwords using the parameter `secrets_as_volumes`, which is included in the `values.yaml` file. By default, this parameter is set to `true` and the passwords are stored as files inside the containers.

Secrets injected as environment variables into the configuration of the container are less secure and are also visible to anyone that has access to inspect the containers. Kubernetes secrets exposed by environment variables can be enumerated on the host via /proc/. The parameter is included in case you want set it as `false` to use environment variables in a testing environment.
