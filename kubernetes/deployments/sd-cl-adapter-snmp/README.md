SD Closed Loop SNMP Adapter Standalone Kubernetes deployment
=============================

This is a standalone Service Director Closed Loop SNMP Adapter for Kubernetes (k8s) deployment, that will deploy the [sd-cl-adapter-snmp](/docker/images/sd-cl-adapter-snmp) container into a kubernetes cluster Pod.

Usage
-----

The SNMP adapter requires a list of Kafka bootstrap nodes to connect to. This must be specified through environment variables, for example if a kubenetes *kafka* service is running in the k8s cluster on port 9092 (see [kafka-zookeper](../../examples/kafka-zookeeper)):

        env:
        - name: SDCONF_asr_adapters_bootstrap_servers
          value: kafka:9092

You can provide any variable supported by Service Director Ansible roles prefixed with `SDCONF_` within the sd-cl-adapter-snmp-deployment.yaml file.

**IMPORTANT** The sd-cl-adapter-snmp-deployment.yaml file defines a docker registry example (hub.docker.hpecorp.net/cms-sd). This shall be changed to point to the docker registry where the sd-cl-adapter-snmp docker image is located: (`- image: hub.docker.hpecorp.net/cms-sd/sd-cl-adapter-snmp`)

**IMPORTANT**: Before deploying the SNMP adapter a namespace with the name "servicedirector" must be created. You have to deploy the file [namespace.yaml](../namespace.yaml) using the following command:

    kubectl create -f namespace.yaml

In order to start Service Director SNMP adapter listening for traps on port 162 (UDP) run:

    kubectl create -f sd-cl-adapter-snmp-deployment.yaml

```
    deployment.apps/sd-cl-adapter-snmp-deployment created
    service/sd-cl-adapter-snmp-nodeport created
```

Validate when the deployed sd-cl-adapter-snmp application/pod is ready (READY 1/1)

    kubectl get pods

```
    NAME                                              READY   STATUS    RESTARTS   AGE
    sd-cl-adapter-snmp-deployment-78d64fdddc-7lqq6    1/1     Running   0          4m
```

When the application is ready, then the deployed service also listen for traps on node port:

    <cluster_ip>:162

**NOTE** The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the sd-cl-adapter-snmp deployment, run:

    kubectl delete -f sd-cl-adapter-snmp-deployment.yaml

```
    deployment.apps/sd-cl-adapter-snmp-deployment deleted
    service/sd-cl-adapter-snmp-nodeport deleted
```
