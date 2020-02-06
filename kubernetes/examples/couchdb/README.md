CouchDB deployment for supporting Service Director UI Kubernetes deployment
==========================

HPE Service Director UI relies on CouchDB as its data persistence module. This example describes how to deploy CouchDB into kubernetes using [Helm](https://helm.sh/).

As mentioned, the Apache Kafka is needed to support the Service Director Kubernetes deployment for the [sd-sp](../../deployments/sd-sp) when it is configured for the Closed Loop together with the [sd-cl-adapter-snmp](../../deployments/sd-cl-adapter-snmp). Those deployment files defines the used Kafka and Kafka-Zookeepers services, which is provided by this Helm chart installation.

It will create a complete CouchDB cluster ready to be used for HPE Service Director as recommended. The following installation will create one replica of CouchDB .

For more information about the CouchDB helm charts, please consult [CouchDB helm](https://github.com/apache/couchdb-helm) page.

**IMPORTANT** Helm version 3 is required to be installed and configured as described in [Using Helm](https://helm.sh/docs/using_helm/) guide. If you are using an older version some helm commands must be changed in order execute them properly.

**NOTE** A guidence in the amount of Memory and Disk for the CouchDB k8s installation together with the full [sd-cl-deployment](../sd-cl-deployment) is that it requires 8GB RAM, 4 CPUs and minimum 50GB free Disk space on the assigned k8s Node. The amount of Memory of cause depends of other applications/pods running in same node. In case k8s master and worker-node are in same host, like Minikube, then minimum 8GB RAM is required.

Usage
-----

In order to make this example compatible with Service Director examples a namespace with the name "servicedirector" must be created. To generate the namespace, run

    kubectl create namespace servicedirector


CouchDB needs to store its data on persistent storage, therefore a persistent volume must be created. This example will explain how to create hostPath PersistentVolumes. Kubernetes supports hostPath for development and testing on a single-node cluster but in a production cluster, you would not use hostPath. The default storage is 10Gb but it can be changed with parameter "persistentVolume.size" to suit your needs. 

To use a local volume, the administrator must create the directory in which the volume will reside and ensure that the permissions on the directory allow write access. Use the following commands to set up the directory:

    mkdir /data/couchdb
    chmod -R 777 /data/couchdb
    
Where "/data/couchdb" is the complete path to the directory in which the volume will reside. If you want to use a different folder you have to modify the file [pv.yaml](./pv.yaml)
If you are using minikube you have to add "  storageClassName: standard" after the "spec:" line to the file [pv.yaml](./pv.yaml)
    
Then you have to deploy the file [pv.yaml](./pv.yaml). In order to create the persistent volume run:

    kubectl create -f pv.yaml  
    
In order to install CouchDB for Service Director into k8s cluster, run:

    helm repo add couchdb https://apache.github.io/couchdb-helm
    helm repo update
    helm install sduicouchdb couchdb/couchdb --set adminUsername=admin,adminPassword=admin,clusterSize=1,persistentVolume.enabled=true  --namespace=servicedirector --version 2.4.1

Validate when the deployed pod is ready (READY 1/1) using the following command:

    kubectl get pods --namespace=servicedirector

the output will show the pod up and running    

```
    NAME                                     READY   STATUS             RESTARTS   AGE
    sduicouchdb-couchdb-0                    1/1     Running            0          5m

```

When the application is ready, then the deployed Github service is exposed with the following:

    kubectl get services --namespace=servicedirector
       
```
    NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)       AGE
    sduicouchdb-couchdb           ClusterIP   None             <none>        5984/TCP      48m
    sduicouchdb-svc-couchdb       ClusterIP   10.111.122.87    <none>        5984/TCP      48m
```



To delete the CouchDB installation, run:

    helm uninstall sduicouchdb --namespace=servicedirector
