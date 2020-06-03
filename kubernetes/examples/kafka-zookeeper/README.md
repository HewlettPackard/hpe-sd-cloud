Kafka deployment for supporting Service Director Closed Loop Kubernetes deployment
==========================

HPE Service Director Closed Loop relies on Apache Kafka as Event collection framework. This example describes how to deploy Apache Kafka into kubernetes using [Helm](https://helm.sh/).

As mentioned, the Apache Kafka is needed to support the Service Director Kubernetes deployment for the [sd-sp](../../deployments/sd-sp) when it is configured for the Closed Loop together with the [sd-cl-adapter-snmp](../../deployments/sd-cl-adapter-snmp). Those deployment files defines the used Kafka and Kafka-Zookeepers services, which is provided by this Helm chart installation.

It will create a complete Kafka and Kafka-Zookeeper cluster ready to be used for HPE Service Director as recommended. The following installation will create one replica of the Kafka and one replica of the Kafka-Zookeeper.

For more information about the Kafka and Kafka Zookeeper helm charts, please consult [Kafka helm](https://github.com/bitnami/charts/tree/master/bitnami/kafka) page.

**IMPORTANT** Helm version 3 is required to be installed and configured as described in [Using Helm](https://helm.sh/docs/using_helm/) guide. If you are using an older version some helm commands must be changed in order execute them properly.

**NOTE** A guidance in the amount of Memory and Disk for the Kafka k8s installation together with the full [sd-cl-deployment](../sd-cl-deployment) is that it requires 8GB RAM, 4 CPUs and minimum 50GB free Disk space on the assigned k8s Node. The amount of Memory of cause depends of other applications/pods running in same node. In case k8s master and worker-node are in same host, like Minikube, then minimum 8GB RAM is required.

Usage
-----

The Kafka image stores the Kafka data at the /bitnami/kafka path of the container.

In order to make this example compatible with Service Director examples a namespace with the name "servicedirector" must be created. To generate the namespace, run

    kubectl create namespace servicedirector


Kafka and Zookeeper need to store its data on persistent storage if persistence is enabled, in that case a persistent volume must be created. A persistent volume (PV) is a cluster resource that you can use to store data for a pod and it persists beyond the lifetime of that pod. The PV is backed by networked storage system such as NFS, you can find more info [here](../../docs/PersistentVolumes.md) on how to setup to your cluster for automatic creation of PV.

In order to install the Kafka and Kafka-Zookeeper for Service Director into k8s cluster, run:

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install kafka bitnami/kafka --namespace=servicedirector

Validate when the deployed sd-aio application/pod is ready (READY 1/1)

    kubectl get pods --namespace=servicedirector

```
    NAME                                     READY   STATUS             RESTARTS   AGE
    kafka-0                                  1/1     Running            5          2h
    kafka-zookeeper-0                        1/1     Running            1          2h
```

When the application is ready, then the deployed kafka services are exposed with the following:

    kubectl get services --namespace=servicedirector

```
    NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
    kafka                         ClusterIP   10.96.43.4       <none>        9092/TCP                        2h
    kafka-headless                ClusterIP   None             <none>        9092/TCP                        2h
    kafka-zookeeper               ClusterIP   10.99.132.14     <none>        2181/TCP,2888/TCP,3888/TCP      2h
    kafka-zookeeper-headless      ClusterIP   None             <none>        2181/TCP,2888/TCP,3888/TCP      2h
```

If you use the kafka to support the [sd-sp](../../deployments/sd-sp) deployment, into the same kubernetes cluster, you can define the container env in the [sd-sp](../../deployments/sd-sp) deployment to point to this kafka service:

```yaml
containers:
- image: hub.docker.hpecorp.net/cms-sd/sd-sp
    imagePullPolicy: Always
    name: sdsp
    env:
    - name: SDCONF_asr_kafka_brokers
    value: kafka:9092
    - name: SDCONF_asr_zookeeper_nodes
    value: kafka-zookeeper:2181
```

If you use the kafka to support the [sd-cl-adapter-snmp](../../deployments/sd-cl-adapter-snmp) deployment, into the same kubernetes cluster, you can define the container env in the [sd-cl-adapter-snmp](../../deployments/sd-cl-adapter-snmp) deployment to point to this kafka service:

```yaml
containers:
- image: hub.docker.hpecorp.net/cms-sd/sd-cl-adapter-snmp
    imagePullPolicy: Always
    name: sd-cl-adapter-snmp
    env:
    - name: SDCONF_asr_adapters_bootstrap_servers
    value: kafka:9092
```

To delete the kafka installation, run:

    helm delete kafka --namespace=servicedirector
