# Service Director deployment in Kubernetes (k8s)

This directory contains several examples which can give you some ideas about how to leverage Service Director (SD) into a kubernetes cluster for development, testing, demo and even production scenarios.

You can find the following subdirectories:

   [sd-ha-deployment](sd-ha-deployment) - Includes a Service Director HA K8s Deployment Scenario (provisioning) using oracle.

   [sd-ha-edb-deployment](sd-ha-edb-deployment) - Includes a Service Director HA K8s Deployment Scenario (provisioning) using EnterpriseDB.

   [sd-cl-deployment](sd-cl-deployment) - Includes closed loop add on to the [sd-ha-deployment](sd-ha-deployment)

   [enterprise-db](enterprise-db) - Includes an enterprise-db K8s deployment example for supporting the SD K8s deployment for the [sd-sp](../deployments/sd-sp)

   [oracle-db](oracle-db) - An oracle-db K8s deployment example for supporting the SD K8s deployment for the [sd-sp](../deployments/sd-sp)

   [kafka-zookeeper](kafka-zookeeper) - A kafka and kafka-zookeeper deployment example using Helm

   [elk](elk) - An example to show Service Director integration with Elastic ELK (ElasticSearch, LogStash and Kirbana). ELK collects and processes data from the multiple Service Directors container logs, stores the data in one centralized data store, and provides a set of tools to analyze the data.

   [redis](redis) - An example of how to integrate Service Director with redis. Redis is used by the Service Director UI to support push notifications and session management for multiple Service Director UI container deployments

**NOTE** A prerequisites for any above deployments is a running kubernetes cluster
