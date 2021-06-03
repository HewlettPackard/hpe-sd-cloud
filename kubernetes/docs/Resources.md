
**Table of Contents**

- [Introduction](#introduction)
- [Resources in a Minikube cluster](#resources-in-a-minikube-cluster)


## Introduction
Minimum requirements, for cpu and memory, are set by default in SD deployed pods. We recommend Kubernetes worker nodes with at least 8Gb and 6 cpus in order to avoid SD pods not starting.

The default values for the resources are set to achieve a standard performance but they can be changed according to your needs.


## Resources in a Minikube cluster
SD values for resource parameters are too high for a default (2048Mb and 2 cpus)  Minikube cluster. In order to run the SD helm chart properly you can use two different approaches.


### Increase Minikube resources
Run the following to give your VM enough resources to run SD helm chart:

    minikube config set memory 8192
    minikube config set cpus 6
    minikube start

This reserves 8 GB of RAM for Minikube and starts it up. If you are low on RAM and only intend to run the Provisioner on Minikube, you can likely get away with a smaller number, like 2048 and 4 cpus.


### Decrease SD pods startup resources
Running a full SD deployment with default Minikube settings is not recommended as some pods won't get the resources they need, but you can run some of the SD smallest deployments if you give less cpu to the SD helm chart pods. Decreasing cpu resources can create some unwanted results, like pods restarts, as Kubernetes will delete pods when they don't start in the defined time window. Therefore you can decrease the following values at your own risk:

    sdimage.cpurequested
    sdui_image.cpurequested
    elk.elastic.cpurequested
    elk.kibana.cpurequested

    
## Troubleshooting


Follow this guide if you experience some problems with your SD Helm chart resources or it is not deploying properly:

#### 1. After deploying SD Helm chart run the following command:

     kubectl get pods

   If there are some pods in "Pending" status go to step 2
   
   If all pods are in "Ready" state go to step 3


#### 2. Some pods in "Pending" status 

   Cluster pod allocation is based on requests (CPU and memory). If a pod requires (claims a request) larger than available CPU or memory in a node, the pod can’t be run on that node. 
   If a Pod is in Pending status it means that it can not be scheduled onto a node. Generally this is because there are insufficient resources of one type or another that prevent scheduling. 
   Let's run this command:
   
      kubectl describe pod <pod-name>

   where <pod-name> is the name of the pod that is in "Pending" state. There should be messages from the scheduler about why it can not schedule your pod. 
   The "Reasons" line can include: 
   
  - You don't have enough resources: You may have exhausted the supply of CPU or Memory in your cluster, in this case you need to adjust resource requests, or add new nodes to your cluster. 
  
  - If description indicates that your pod has been "Evicted" go to to step 5  
      
   - Is the readiness probe failing?  
   
     Your cluster has not enough resources (memory or cpu) to deploy all pods at the same time and it is taking more time than expected to deploy sucessfully any pod. The solution is to fix the readiness probe and set higher time values for the parameters, for example "initialDelaySeconds". Redeploy the Helm chart with the new values.
         
  - Some image in the pod is been pulled or cannot be pulled from repository. There are three things to check:

   1. Make sure that you have the name of the image correct.
   2. Can you connect to the repository?
   3. Run a manual docker pull <image> on your machine to see if the image can be pulled

   If there is enough resources in the cluster go to step 4
   
#### 3. All pods in "Ready" state  

The SD pods are running but not doing what they are supposed to do.

If your pod is not behaving as you expected, it may be that there was an error in your values files (e.g. values.yaml contains incorrect values), and the error was silently ignored when you deployed the pod. Check the values file for parameters that are not nested incorrectly, or a key name that is typed incorrectly, and so the key is ignored. 

Manually compare the original values.yaml with the one included in your distribution, if there are lines on the original that are not on the deployed version, then this may indicate a problem with your pod spec.

You should also check if the network bandwidth between the sd-sp pod and the database is good enough.



#### 4. Check ResourceQuota limits and pending PVC

If you are hitting the ResourceQuota limits then relax these limits.
Check if there are any pending PVC with this command:
   
      kubectl get pvc
      
If there are any pending PVC then you must check if there is any valid StorageClass' assigned in the values.yaml parameters or if there is any default StorageClass in the cluster.
  
#### 5. Pod eviction

When a Kubernetes WorkerNode in a cluster lacks available resources - as memory, disc, CPU, etc. a cluster’s scheduler stops adding new pods on that node.

Kubernetes adds special annotations to such a node describing its status, for example – node.kubernetes.io/memory-pressure. You can find the full list here https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/#taint-based-evictions
 
   Execute the following commands to find out if there is any problem with the resorces in some of the cluster's nodes:
   
       kubectl get events
       
       kubectl describe node <insert-node-name-here>
       

  
    
