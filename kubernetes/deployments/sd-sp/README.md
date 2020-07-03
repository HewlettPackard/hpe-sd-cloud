Service Director Standalone Kubernetes deployment
=============================

This is a standalone Service Director Kubernetes (k8s) deployment, that will deploy the [sd-sp](/docker/images/sd-sp) container into a kubernetes cluster Pod.
It includes Service Activator plus DDE (provisioning and closed loop) and additional solutions. An external database is required. When starting a container for the first time, Service Activator will be configured creating the required database structure (if it is the first node of the cluster) or adding itself to an existing SA cluster.

Usage
-----

As before mentioned, the standalone provisioning deployment requires an external database instance. Such instance may also be in a k8s deployment or just a regular one.

For this example, we bring up an instance of the `postgres` image in a K8S Pod, which is basically a clean PostgreSQL 11 image with a `sa` user ready for Service Director installation.

**NOTE**: If you are not using the K8S [postgres-db](../../examples/postgres-db) deployment, then you need to modify the [sd-sp-deployment.yaml](sd-sp-deployment.yaml) database related environments to point to the used database.

The following databases are available:

- Follow the deployment as described in [postgres-db](../../examples/postgres-db) directory.
- Follow the deployment as described in [enterprise-db](../../examples/enterprise-db) directory.
- Follow the deployment as described in [oracle-db](../../examples/oracle-db) directory.

**NOTE**: For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Postgres' [docker-images](https://hub.docker.com/_/postgres), EDB Postgres' [docker-images](http://containers.enterprisedb.com) or the official Oracle's [docker-images](https://github.com/oracle/docker-images).

Note that the specified database user must already exist and, in case you are creating the first node of a cluster, it must be empty.

If you want the deployed container to act as a closed-loop backend node, you need to specify some additional variables in the [sd-sp-deployment.yaml](sd-sp-deployment.yaml) file:

If you are willing to run the closed-loop in the cluster, you need to specify the following environment variable for all cluster nodes:

    SDCONF_install_asr=yes

Then on those nodes you want to run the closed-loop on:

    SDCONF_asr_kafka_brokers=kafka1:9092,kafka2:9092,kafka3:9092
    SDCONF_asr_zookeeper_nodes=zookeeper1:2181,zookeeper2:2181,zookeeper3:2181

If you want a node in the cluster to not run the closed-loop (you still need to specify `SDCONF_install_asr=yes` for all of them):

    SDCONF_asr_node=no

By default if the closed-loop is deployed nodes will run it so there is no need to ever specify `SDCONF_asr_node=yes`.

**NOTE**: An Apache kafka and kafka-zookeeper application installation example for K8s is available for testing purposes - see [kafka-zookeper](../../examples/kafka-zookeeper). By default the [sd-sp-deployment.yaml](sd-sp-deployment.yaml) uses the example k8s kafka and kafka-zookepers services installed by the example.

Additionally, if you want the node to act as a pure closed-loop node, without running workflows, you can specify

    SDCONF_asr_only_node=yes

You can provide any variable supported by Service Director Ansible roles prefixed with `SDCONF_` within the [sd-sp-deployment.yaml](sd-sp-deployment.yaml) file.

**IMPORTANT**: The [sd-sp-deployment.yaml](sd-sp-deployment.yaml) file defines a docker registry example (`hub.docker.hpecorp.net/cms-sd`). This shall be changed to point to the docker registry where the sd-sp docker image is located: (`- image: hub.docker.hpecorp.net/cms-sd/sd-sp`)

**IMPORTANT**: Before deploying Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run:

    kubectl create namespace servicedirector

In order to deploy the standalone Service Director Provisioning K8s deployment, run:

    kubectl create -f sd-sp-deployment.yaml

```
statefulset.apps/sd-sp created
service/sd-sp-nodeport created
```

Validate when the deployed sdsp application/pod is ready (READY 1/1)

    kubectl get pods --namespace servicedirector

```
NAME                                READY   STATUS    RESTARTS   AGE
sd-sp-0                             1/1     Running   0          10m
```

When the application is ready, then the deployed service (SD Native UI) is exposed on the following url:

    http://<cluster_ip>:32514/login

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the sdsp deployment, run:

    kubectl delete -f sd-sp-deployment.yaml

```
statefulset.apps "sd-sp" deleted
service "sd-sp-nodeport" deleted
```


## Using a Service Director license

By default, a 30-day Instant On license will be used. If you have a license file, you can supply it by creating a secret and bind-mounting it at `/license`, like this:

    kubectl create secret generic sd-license-secret --from-file=license=<license-file> -n servicedirector

Where `<license-file>` is the path to your Service Director license file.

It is also necessary to create a volume and mount it. To do so the following piece of code should be added to the Service Director StatefulSet file [sd-sp-deployment.yaml](sd-sp-deployment.yaml):

```yaml
spec:
  containers:
  - image: hub.docker.hpecorp.net/cms-sd/sd-sp
    imagePullPolicy: Always
    name: sd-sp

    [...]

    lifecycle:
      postStart:
        exec:
          command:
            - /bin/sh
            - -c
            - cp /mnt/license /license
    volumeMounts:
    - name: sd-license
      mountPath: "/mnt"
      readOnly: true
  volumes:
  - name: sd-license
    secret:
      secretName: sd-license-secret
```


## How to scale up/down standalone Service Director nodes

The default standalone Service Director replicas is 1, if you want scale up/down the number of nodes you can use the following command:

    kubectl scale statefulset sd-sp --replicas=x --namespace servicedirector

where x is the number of replicas you want to run
