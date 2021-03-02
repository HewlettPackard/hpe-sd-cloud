# Oracle DB example deployment for supporting Service Director Kubernetes deployment

**NOTE** For production environments you should either use an external, non-containerized database or create an image of your own.

This is an oracle-db Kubernetes (K8S) deployment example for supporting the Service Director Kubernetes deployment for the [Helm Chart](/kubernetes/helm). It deploys the [oracledb-18xe-sa](/docker/examples/images/oracledb-18xe-sa) container into a kubernetes cluster Pod.

It will create a Pod with an Oracle database prepared to install Service Director as recommended. There is an `hpsa` user (password is `secret`) with all the privileges required for a Service Activator installation. The image also supports health check which is used for a [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/).

**NOTE**: A guidance in the amount of Memory and Disk for the oracle database K8S deployment is that it requires 4GB RAM and minimum 15GB free Disk space on the assigned K8S Node. The amount of Memory of course depends of other applications/pods running in same node. In case K8S master and worker-node are in same host, like Minikube, then minimum 5GB RAM is required.

**IMPORTANT**: Before deploying Service Director a namespace with the name "sd" must be created. In order to generate the namespace, run

    kubectl create namespace sd

## Usage

In order to deploy the oracle-18xe-sa for Service Director in a single K8S Pod, run:

    kubectl create -f oracle-18xe-sa-deployment.yaml

```
deployment.apps/oracle18xe-deployment created
service/oracle18xe-nodeport created
```

Validate when the deployed sd-aio application/pod is ready (READY 1/1):

    kubectl get pods --namespace sd

```
NAME                                     READY   STATUS    RESTARTS   AGE
oracle18xe-deployment-5f8678bf9b-566x5   1/1     Running   0          18m
```

When the application is ready, then the deployed oracle service is exposed with the following:

```
Hostname: <cluster_ip>
Port: 30021
SID: xe
```

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

If you use the database to support the [Helm Chart](/kubernetes/helm), into the same kubernetes cluster, you can define the container env in the deployment to point to this db-instance hostname by using the kubernetes service name `oracle18xe-nodeport`:

```yaml
containers:
- image: hub.docker.hpecorp.net/cms-sd/sd-sp
  imagePullPolicy: Always
  name: sd-sp
  env:
    - name: SDCONF_activator_db_vendor
      value: Oracle
    - name: SDCONF_activator_db_hostname
      value: oracle18xe-nodeport
    - name: SDCONF_activator_db_instance
      value: XE
    - name: SDCONF_activator_db_user
      value: hpsa
    - name: SDCONF_activator_db_password
      value: secret
```

To delete the oracle-18xe-sa, run:

    kubectl delete -f oracle-18xe-sa-deployment.yaml

```
deployment.apps "oracle18xe-deployment" deleted
service "oracle18xe-nodeport" deleted
```
