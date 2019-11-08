Enterprise DB deployment example for supporting Service Director Kubernetes deployment
==========================

This is an enterprise-db Kubernetes (k8s) deployment example for supporting the Service Director Kubernetes deployment for the [sd-sp](../deployments/sd-sp). It deploys the EnterpriseDB Lite container into a kubernetes cluster Pod..

It will create a Pod with an EnterpriseDB database prepared to install Service Director as recommended. There is an `enterprisedb` user (password is `secret`) with all the privileges required for a Service Activator installation. The image also supports health check which is used for a [RedinessProbes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)

In order to use this example a valid EnterpriseDB user account must be used. The credentials are stored in a Secret object in the deployment file, use the following steps to configure it before you use it with Kubernetes:

1.You must authenticate with EDB registry in order to pull a private image:

      docker login http://containers.enterprisedb.com
      
       When prompted, enter your EDB username and the particular password for the containers registry.

2. The login process creates or updates a ~/.docker/config.json file that holds an authorization token.

3. Base64 encode the config.json file and paste the string generated on the .dockerconfigjson data item

EnterpriseDB requires a volume in order to store the database files, therefore a PersistentVolume and PersistentVolumenClaim has been added to the deployment file. The storage values can be increased to adjust the storage data to your requirements, the storage path can be change to create the volume in an alternative folder that suits you.  

**NOTE** A guidence in the amount of Memory and Disk for the EnterpriseDB database k8s deployment is that it requires 2GB RAM and minimum 512M free Disk space on the assigned k8s Node. The amount of Memory of cause depends of other applications/pods running in same node. In case k8s master and worker-node are in same host, like Minikube, then minimum 5GB RAM is required.

Usage
-----

In order to deploy the EnterpriseDB for Service Director in a single k8s Pod, run

    kubectl create -f enterprisedb-deployment.yaml

```
persistentvolume/edb-data-volume created
persistentvolumeclaim/edb-data-pvc created
secret/logintoken created
deployment.apps/enterprisedb-deployment created
service/enterprisedb-nodeport created

```

Validate when the deployed enterprisedb application/pod is ready (READY 1/1)

     kubectl get pods

```
     NAME                                     READY   STATUS    RESTARTS   AGE
     enterprisedb-deployment-76d5c4cd66-mvrzl   1/1     Running   0          71s
```

When the application is ready, then the deployed EnterpriseDB service are exposed with the following:

      Hostname: <cluster_ip>
      Port: 30021
      SID: HPSA
      


**NOTE** The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`


If you use the database to support the [sd-sp](../../deployments/sd-sp) deployment, into the same kubernetes cluster, you can define the container env in the [sd-sp](../../deployments/sd-sp) deployment to point to this db-instance hostname by using the kubernetes service name `enterprisedb-nodeport`:

```
  containers:
      - image: hub.docker.hpecorp.net/cms-sd/sd-sp
        imagePullPolicy: IfNotPresent
        name: sdsp
        env:
        - name: SDCONF_hpsa_db_hostname
          value: enterprisedb-nodeport

```

To delete the EnterpriseDB, run

     kubectl delete -f enterprisedb-deployment.yaml

```
persistentvolume "edb-data-volume" deleted
persistentvolumeclaim "edb-data-pvc" deleted
secret "logintoken" deleted
deployment.apps "enterprisedb-deployment" deleted
service "enterprisedb-nodeport" deleted

```
