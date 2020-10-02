
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
