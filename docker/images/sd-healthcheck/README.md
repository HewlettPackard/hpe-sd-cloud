SD Healthcheck Image
============================

This image monitors the pods status after the SD deployment using the helm chart.

Usage
-----
The sd_healthcheck image uses the k8s Rest-API, so it can only be used in k8s deployments!

## Deploy healthcheck with the SD helm chart

Healthcheck pod comes as optional in SD helm chart. 

Use this [link](https://github.hpe.com/hpsd/sd-cloud/tree/master/kubernetes/helm/charts#healthcheck-pod-for-service-director) to get information about activating and deploying with SD helm chart



## Pull the image from Docker repository

You can download the lastest healthcheck image from Docker using this command:

        docker pull hub.docker.hpecorp.net/cms-sd/sd-healthcheck

Previously you have to login in the Docker repository using the "docker login" command.


