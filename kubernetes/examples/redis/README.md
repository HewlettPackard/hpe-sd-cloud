REDIS example deployment for supporting Service Director Kubernetes deployment
==========================

This is an redis Kubernetes (k8s) deployment example for supporting the Service Director Kubernetes deployment for the [sd-sp](../deployments/sd-sp). It deploys the [redis](/docker/examples/images/redis-sd) container into a kubernetes cluster Pod.

It will create a Pod with an Redis in-memory data structure store prepared to install Service Director as recommended. The image also supports health check which is used for a [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/).


**NOTE**: A guidance in the amount of Memory and Disk for redis k8s deployment is that it requires 4GB RAM and minimum 20GB free Disk space on the assigned k8s Node. The amount of Memory of cause depends of other applications/pods running in same node. In case k8s master and worker-node are in same host, like Minikube, then minimum 5GB RAM is required.

Usage
-----

In order to deploy Redis for Service Director in a single k8s Pod, run

    kubectl create -f sd-redis-deployment.yaml

```
secret/redis-password created
configmap/redis-config created
deployment.apps/redis-deployment created
service/redis-service created
```

Validate when the deployed sd-aio application/pod is ready (READY 1/1)

    kubectl get pods

```
NAME                                     READY   STATUS    RESTARTS   AGE
redis-deployment-779c67878b-95pzm        1/1     Running   0          77s
```

When the application is ready, then the deployed redis service is exposed inside the cluster with the following:

```
Hostname: <cluster_ip>
Port: 6379
```

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl get services redis-service`

If you use redis to support the [sd-ui](../deployments/sd-ui) deployment, into the same kubernetes cluster, you have to add some extra container env in the [sd-ui](../deployments/sd-ui) deployment to point to this db-instance hostname by using the following kubernetes environment variables:

```yaml
containers:
- image: sd-ui
  imagePullPolicy: Always
  name: sd-ui
  env:
  - name: SDCONF_sdui_redis
    value: "yes"
  - name: SDCONF_sdui_redis_host
    value: redis-service
  - name: SDCONF_sdui_redis_port
    value: "6379"
  - name: SDCONF_sdui_redis_password
    value: secret
  - name: SDCONF_sdui_async_host
    value: <ui-host>
```

The extra parameter SDCONF_sdui_async_host must contain the name of the Kubernetes service for the SD_UI pod so the Service Provisioner knows where to do the callback.

To delete the redis pod, run

    kubectl delete -f sd-redis-deployment.yaml

```
secret "redis-password" deleted
configmap "redis-config" deleted
deployment.apps "redis-deployment" deleted
service "redis-service" deleted
```

Redis needs to store its data on persistent storage if persistence is enabled, in that case a persistent volume must be created. A persistent volume (PV) is a cluster resource that you can use to store data for a pod and it persists beyond the lifetime of that pod. The PV is backed by networked storage system such as NFS, you can find more info [here](../../docs/PersistentVolumes.md)  on how to setup to your cluster for automatic creation of PV.
