# Service Director CL K8s Deployment Scenario

This Deployment file defines a standard Service Director Closed Loop deployment for kubernetes cluster with Closed Loop nodes, Apache kafka, a SNMP Adapter and a Service Director UI as well. 

As a prerequisites for this deployment is a database and the Apache Kafka/Kafka-Zookeeper is required.

## Prerequisites
### 1. Deploy oracle database

**If you have already deployed a database, you can skip this step!**

For this example, we bring up an instance of the `oracledb-18xe-sa` image in a K8s Pod, which is basically a clean Oracle XE 18c image with an `hpsa` user ready for Service Director installation.

**NOTE** If you are not using the k8s [oracle-db](../oracle-db) deployment, then you need to modify the [sd-cl-deployment](sd-cl-deployment.yaml) database related environments to point to the used database.

Follow the deployment as described in [oracle-db](../oracle-db) directory. 

**NOTE** For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Oracle's [docker-images](https://github.com/oracle/docker-images).

### 2. Deploy Apache Kafka and Kafka-Zookeeper
To deploy the Apache kafka and Kafka-Zookeeper, we use a Helm Chart to easily bring up the kafka services.

Follow the deployment as described in the [kafka-zookeper](../kafka-zookeeper) example.

## SD Closed Loop Deployment

The [sd-cl-deployment.yaml](sd-cl-deployment.yaml) file contains the following deployments (k8s-Pods):

- `sd-sp-deployment`             : HPE SD Provisioning node - [sd-sp](/docker/images/sd-sp)
- `sd-cl-deployment`             : HPE SD Closed Loop node - [sd-sp](/docker/images/sd-sp)
- `sd-ui-cl-deployment`          : UOC-based UI connected to `sd-sp-cl-deployment` HPE Service Director - [sd-ui](/docker/images/sd-ui)
- `sd-cl-adapter-snmp-deployment`: SD Closed Loop SNMP Adapter - [sd-sp](/docker/images/sd-sp)


The following services are exposed to external ports in the k8s cluster:
- `sd-sp-nodeport`                -> `32517`: Service Director native UI
- `sd-cl-nodeport`                -> `32518`: Service Director native UI
- `sdui-cl-nodeport`              -> `32519`: Unified OSS Console (UOC) for primary Service Director
- `sd-cl-adapter-snmp-nodeport`   -> `32162`: Closed Loop SNMP Adapter Service Director

In order to guarantee that services are started in the right order, and to avoid a lot of initial restarts of the applications, until the prerequisites are fullfilled, this deployment file makes use of [k8s initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).
The initContianers are not mandatory. 
Further it adds k8s [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) and [livenessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) to the applications to do health check. 

If you are using an external database, you need to adjust `SDCONF_activator_db_`-prefixed environment variables as appropriate for the `sd-cl-deployment`, also you need to make sure that your database is ready to accept connections before deploying the k8s [sd-cl-deployment](sd-cl-deployment.yaml).

**IMPORTANT** The [sd-cl-deployment.yaml](sd-cl-deployment.yaml) file defines a docker registry examples (`hub.docker.hpecorp.net/cms-sd`) for the used images. This shall be changed to point to the docker registry where the docker images are located. E.g.: (`- image: hub.docker.hpecorp.net/cms-sd/sd-sp`)

**NOTE** A guidence in the amount of Memory and Disk for the sd-cl K8s deployment is that it requires 4GB RAM and minimum 25GB free Disk space on the assigned K8s nodes running the `sdui-cl-deployment`. The amount of Memory of cause depends of other applications/pods running in same node. 
In case K8s master and worker-node are in same host, like Minikube, then minimum 16GB RAM and 80GB Disk is required.

In order to deploy the Service Director Closed Loop K8s deployment, run:

    kubectl create -f sd-cl-deployment.yaml

```
    deployment.apps/sd-sp-deployment created
    service/sd-sp-nodeport created
    deployment.apps/sd-cl-deployment created
    service/sd-cl-nodeport created
    deployment.apps/sd-ui-cl-deployment created
    service/sdui-cl-nodeport created
    deployment.apps/sd-cl-adapter-snmp-deployment created
    service/sd-cl-adapter-snmp-nodeport created
```

Validate when the deployed sd-cl applications/pods are ready (READY 1/1)

    kubectl get pods

```
    NAME                                            READY   STATUS    RESTARTS   AGE
    sd-sp-deployment-74ff568f8d-aa5ht               1/1     Running   0          15m
    sd-cl-deployment-74ff658f7d-bb8hv               1/1     Running   0          15m
    sd-ui-cl-deployment-ddbc6b499-ddp9t             1/1     Running   0          15m
    sd-cl-adapter-snmp-deployment-65cb7dc8f7-8f2px  1/1     Running   0          15m
```

When the SD HA applications are ready, then the deployed services (SD User Interfaces) are exposed on the following urls:
    
    
    Service Director UI:
        http://<cluster_ip>:32519/login       (Service Director UI)
        
        http://<cluster_ip>:32517/activator/  (Service Director provisioning native UI)
        http://<cluster_ip>:32518/activator/  (Service Director closed loop native UI)

**NOTE** The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

    kubectl delete -f sd-cl-deployment.yaml

```
    deployment.apps/sd-sp-deployment deleted
    service/sd-sp-nodeport deleted
    deployment.apps/sd-cl-deployment deleted
    service/sd-cl-nodeport deleted
    deployment.apps/sd-ui-cl-deployment deleted
    service/sdui-cl-nodeport created
    deployment.apps/sd-cl-adapter-snmp-deployment deleted
    service/sd-cl-adapter-snmp-nodeport deleted
```

To delete the oracle and Apache kafka and kafka-zookeepers, please follow the delete procedures as described in the respective examples.
