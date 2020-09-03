
**Table of Contents**

  - [Introduction](#introduction)
  - [Helm chart parameters](#helm-chart-parameters)
  - [Resources in a Minikube cluster](#resources-in-a-minikube-cluster)


## Introduction

Minimum requirements, for cpu and memory, are set by default in SD deployed pods. We recommend Kubernetes worker nodes with at least 8Gb and 6 cpus in order to avoid SD pods not starting.

The default values for the resources are set to achieve a standard performance but they can be changed according to your needs. 


## Helm chart parameters

The following table lists resource configurable parameters of the SD chart and their default values. See [values.yaml](../helm/sd-chart/chart/values.yaml) for all available options.

| Parameter                                 | Description                                                       | Default   |
|-------------------------------------------|-------------------------------------------------------------------|-----------|
| `sdimage.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the Closed Loop or Provisioner container  | `1Gb`    |
| `sdimage.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the Closed Loop or Provisioner container    | `3`    |
| `sdimage.memorylimit`                         | Max. amount of memory a cluster node will provide to the Closed Loop or Provisioner container. No limit by default.       | null    |
| `sdimage.cpulimit`                           | Max. amount of cpu a cluster node will provide to the Closed Loop or Provisioner container. No limit by default.       | null    |
| `sdimage.filebeat.memoryrequested`          |  Amount of memory a cluster node needs to provide in order to start the CL-SP filebeat container in the ELK example.  | `10Mb`    |
| `sdimage.filebeat.cpurequested`           | Amount of cpu a cluster node needs to provide in order to start the CL-SP filebeat container in the ELK example.    | `0.1`    |
| `sdimage.filebeat.memorylimit`  | Max. amount of memory a cluster node will provide to the CL-SP filebeat container in the ELK example. No limit by default.       | null    |
| `sdimage.filebeat.cpulimit`          | Max. amount of memory a cluster node will provide to the CL-SP filebeat container in the ELK example. No limit by default.       | null    |
| `sdimage.grokexporter.memoryrequested`          |  Amount of memory a cluster node needs to provide in order to start the grokexporter container in the Prometheus example.  | `100Mb`    |
| `sdimage.grokexporter.cpurequested`                       | Amount of cpu a cluster node needs to provide in order to start the grokexporter container in the Prometheus example.    | `0.1`    |
| `sdimage.grokexporter.memorylimit`  | Max. amount of memory a cluster node will provide to the grokexporter container in the Prometheus example. No limit by default.       | null    |
| `sdimage.grokexporter.cpulimit`  | Max. amount of memory a cluster node will provide to the grokexporter container in the Prometheus example. No limit by default.       | null    |
| `sdui_image.memoryrequested`|  Amount of memory a cluster node needs to provide in order to start the UI container  | `300Mb`    |
| `sdui_image.cpurequested`    | Amount of cpu a cluster node needs to provide in order to start the UI container    | `0.7`    |
| `sdui_image.memorylimit`   | Max. amount of memory a cluster node will provide to the UI container. No limit by default.       | null    |
| `sdui_image.cpulimit`                 | Max. amount of cpu a cluster node will provide to the UI container. No limit by default.       | null    |
| `sdui_image.filebeat.memoryrequested`          |  Amount of memory a cluster node needs to provide in order to start the UI filebeat container in the ELK example.  | `100Mb`    |
| `sdui_image.filebeat.cpurequested`           | Amount of cpu a cluster node needs to provide in order to start the UI filebeat container in the ELK example.    | `0.1`    |
| `sdui_image.filebeat.memorylimit`  | Max. amount of memory a cluster node will provide to the UI filebeat container in the ELK example. No limit by default.       | null    |
| `sdui_image.filebeat.cpulimit`          | Max. amount of memory a cluster node will provide to the UI filebeat container in the ELK example. No limit by default.       | null    |
| `deployment_sdsnmp.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the SNMP adapter container  | `150Mb`    |
| `deployment_sdsnmp.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the SNMP adapter container    | `0.1`    |
| `deployment_sdsnmp.memorylimit`                         | Max. amount of memory a cluster node will provide to the SNMP adapter container. No limit by default.       | null    |
| `deployment_sdsnmp.cpulimit`                           | Max. amount of cpu a cluster node will provide to the SNMP adapter container. No limit by default.       | null    |
| `prometheus.cadvisor.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the CAdvisor container in the Prometheus example  | `150Mb`    |
| `prometheus.cadvisor.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the CAdvisor container in the Prometheus example.    | `0.1`    |
| `prometheus.cadvisor.memorylimit`                     | Max. amount of memory a cluster node will provide to the CAdvisor container in the Prometheus example. No limit by default.       | null    |
| `prometheus.cadvisor.cpulimit`                           | Max. amount of cpu a cluster node will provide to the CAdvisor container in the Prometheus example. No limit by default.       | null    |
| `prometheus.cadvisor.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the CAdvisor container in the Prometheus example  | `300Mb`    |
| `prometheus.cadvisor.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the CAdvisor container in the Prometheus example.    | `0.2`    |
| `prometheus.cadvisor.memorylimit`                     | Max. amount of memory a cluster node will provide to the CAdvisor container in the Prometheus example. No limit by default.       | null    |
| `prometheus.cadvisor.cpulimit`                           | Max. amount of cpu a cluster node will provide to the CAdvisor container in the Prometheus example. No limit by default.       | null    |
| `prometheus.grafana.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the Grafana container in the Prometheus example  | `100Mb`    |
| `prometheus.grafana.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the Grafana container in the Prometheus example.    | `0.2`    |
| `prometheus.grafana.memorylimit`                     | Max. amount of memory a cluster node will provide to the Grafana container in the Prometheus example. No limit by default.       | null    |
| `prometheus.grafana.cpulimit`                           | Max. amount of cpu a cluster node will provide to the Grafana container in the Prometheus example. No limit by default.       | null    |
| `prometheus.sqlexporter.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the sqlexporter container in the Prometheus example  | `50Mb`    |
| `prometheus.sqlexporter.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the sqlexporter container in the Prometheus example.    | `0.1`    |
| `prometheus.sqlexporter.memorylimit`                     | Max. amount of memory a cluster node will provide to the sqlexporter container in the Prometheus example. No limit by default.       | null    |
| `prometheus.sqlexporter.cpulimit`                           | Max. amount of cpu a cluster node will provide to the sqlexporter container in the Prometheus example. No limit by default.       | null    |
| `prometheus.ksm.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the kube-state-metrics container in the Prometheus example  | `50Mb`    |
| `prometheus.ksm.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the kube-state-metrics container in the Prometheus example.    | `0.1`    |
| `prometheus.ksm.memorylimit`                     | Max. amount of memory a cluster node will provide to the kube-state-metrics container in the Prometheus example. No limit by default.       | null    |
| `prometheus.ksm.cpulimit`                           | Max. amount of cpu a cluster node will provide to the kube-state-metrics container in the Prometheus example. No limit by default.       | null    |
| `elk.elastic.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the Elasticsearch container in the ELK example  | `1.3Gb`    |
| `elk.elastic.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the Elasticsearch container in the ELK example.    | `0.4`    |
| `elk.elastic.memorylimit`                     | Max. amount of memory a cluster node will provide to the Elasticsearch container in the ELK example. No limit by default.       | null    |
| `elk.elastic.cpulimit`                           | Max. amount of cpu a cluster node will provide to the Elasticsearch container in the ELK example. No limit by default.       | null    |
| `elk.kibana.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the Kibana container in the ELK example  | `400Mb`    |
| `elk.kibana.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the Kibana container in the ELK example.    | `0.3`    |
| `elk.kibana.memorylimit`                     | Max. amount of memory a cluster node will provide to the Kibana container in the ELK example. No limit by default.       | null    |
| `elk.kibana.cpulimit`                           | Max. amount of cpu a cluster node will provide to the Kibana container in the ELK example. No limit by default.       | null    |
| `elk.logstash.memoryrequested`               |  Amount of memory a cluster node needs to provide in order to start the Logstash container in the ELK example  | `350Mb`    |
| `elk.logstash.cpurequested`                         | Amount of cpu a cluster node needs to provide in order to start the Logstash container in the ELK example.    | `0.1`    |
| `elk.logstash.memorylimit`                     | Max. amount of memory a cluster node will provide to the Logstash container in the ELK example. No limit by default.       | null    |
| `elk.logstash.cpulimit`                           | Max. amount of cpu a cluster node will provide to the Logstash container in the ELK example. No limit by default.       | null    |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.


## Resources in a Minikube cluster

SD values for resource parameters are too high for a default (204bMb and 2 cpus)  Minikube cluster. In order to run the SD helm chart properly you can use two different approaches:

#### Increase Minikube resources

Run the following to give your VM enough resources to run SD helm chart:

    minikube config set memory 8192
    minikube config set cpus 6
    minikube start

This reserves 8 GB of RAM for Minikube and starts it up. If you are low on RAM and only intend to run the Provisioner on Minikube, you can likely get away with a smaller number, like 2048 and 4 cpus.

#### Decrease SD pods startup resources

Running a full SD deployment with default Minikube settings is not recommended as some pods won't get the resources they need, but you can run some of the SD smallest deployments if you give less cpu to the SD helm chart pods. Decreasing cpu resources can create some unwanted results, like pods restarts, as Kubernetes will delete pods when they don't start in the defined time window. Therefore you can decrease the following values at your own risk:

    sdimage.cpurequested
    sdui_image.cpurequested
    elk.elastic.cpurequested
    elk.kibana.cpurequested