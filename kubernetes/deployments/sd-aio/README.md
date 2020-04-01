SD All-in-One Kubernetes deployment
==========================

This is an all-in-one Kubernetes (k8s) deployment for Service Director, that will deploy the [sd-aio](/docker/images/sd-aio) container into a kubernetes cluster Pod. It includes both SD-Provisioning, SD-Closed-Loop and the UOC-based UI. Required databases for both Service Director (Oracle XE) and UOC (CouchDB) are included as well.

It will create one sd-aio container running in a k8s Pod.

**NOTE**: A guidance in the amount of Memory and Disk for the sd-aio k8s deployment is that it requires 4GB RAM and minimum 15GB free Disk space on the assigned k8s Node. The amount of Memory of cause depends of other applications/pods running in same node. In case k8s master and worker-node are in same host, like Minikube, then minimum 5GB RAM is required.

Usage
-----

**IMPORTANT**: The sd-aio-deployment.yaml file defines a docker registry example (hub.docker.hpecorp.net/cms-sd). This shall be changed to point to the docker registry where the sd-aio docker image is located: (`- image: hub.docker.hpecorp.net/cms-sd/sd-aio`)

**IMPORTANT**: Before deploying all-in-one Service Director a namespace with the name "servicedirector" must be created. In order to generate the namespace, run:

    kubectl create namespace servicedirector

In order to deploy the all-in-one Service Director in a single k8s Pod, run:

    kubectl create -f sd-aio-deployment.yaml

```
deployment.apps/sd-aio created
service/sd-aio-nodeport created
```

Validate when the deployed sd-aio application/pod is ready (READY 1/1)

    kubectl get pods --namespace servicedirector

```
NAME                        READY   STATUS    RESTARTS   AGE
sd-aio-5667cdcdbc-dcbvv     1/1     Running   0          10m
```

When the application is ready, then the deployed service (SD User Interfaces) are exposed on the following urls:

    http://<cluster_ip>:32513/login

    http://<cluster_ip>:32514/activator/

**NOTE** The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the sd-aio deployment, run:

    kubectl delete -f sd-aio-deployment.yaml

```
deployment.apps "sd-aio" deleted
service "sd-aio-nodeport" deleted
```
