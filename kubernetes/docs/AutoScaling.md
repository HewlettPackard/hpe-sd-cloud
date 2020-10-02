
**Table of Contents**

  - [Introduction](#introduction)
  - [Create an Horizontal Pod Autoscaler](#create-an-horizontal-pod-autoscaler)
  - [Example of autoscaling on external metrics](#example-of-autoscaling-on-external-metrics)


## Introduction

One of the Kubernetes features is the ability to scale an application horizontally when there is an increased resource usage. Natively, horizontal pod autoscaling can scale the deployment based on CPU and Memory usage but in some scenarios we would want to account for other metrics before making scaling decisions.

The Kuberntes metrics-server monitoring needs to be deployed in the Kubernetes cluster to provide metrics, as Horizontal Pod Autoscaler uses its API to collect metrics. Usually the metrics-server monitoring will be turned-on by default in a standard Kubernetes cluster.



## Create an Horizontal Pod Autoscaler

The following command will create a Horizontal Pod Autoscaler (HPA) that maintains between 1 and 8 replicas of the sd-cl (CLosedLoop) Pods created during the Service Director deployment:

     kubectl autoscale statefulset sd-cl --cpu-percent=90 --min=1 --max=8


HPA will increase and decrease the number of replicas to maintain an average CPU utilization across all Pods of 90%. The CPU utilization is based on the parameter from the sd-cl container's value:

        resources:
          requests:
            cpu: 3000m

This value is set using the parameter `sdimage.cpurequested` as detailed in this [link](./Resources.md)

Since each pod originally requests 3000 milli-cores (3 cores), after the HPA is deployed the limit will be %90 or 2700 milli-cores. This means a new pod instance will be created when a sd-cl intance reaches  average CPU usage of 2700 milli-cores.



## Example of autoscaling on external metrics

Service Director may need to autoscale based on metrics that don't have an obvious relationship to any object in the Kubernetes cluster, such as metrics describing the number of workflows executing simultaneously. You can address this use case with external metrics.

In this case we will use the [Prometheus Adapter](https://github.com/helm/charts/tree/master/stable/prometheus-adapter) for Kubernetes Metrics APIs as the SD-Prometheus already provides metrics that can be used for this purpose.

This adapter is suitable for use with the autoscaling/v2 Horizontal Pod Autoscaler in Kubernetes 1.6+,


In order to install Prometheus Adapter using Helm, the repo must be added previously using the following command:

    helm repo add stable https://kubernetes-charts.storage.googleapis.com


A standard way to deploy the Prometheus Adapter is the following:


    helm install promadapter stable/prometheus-adapter --set prometheus.url=http://prometheus-service.monitoring

where 'prometheus-service.monitoring' is the name of the Prometheus service deployed with the sd-Prometheus example.

The standard deployment is not useful as it does not include what Prometheus metrics we want to use for the HPA. In order to accomplish this objective we need to add some rules to the adapter's configuration using a modified 'values.yaml' file for the Prometheus adapter's Helm chart:


```yaml
affinity: {}
image:
  repository: directxman12/k8s-prometheus-adapter-amd64
  tag: v0.6.0
  pullPolicy: IfNotPresent
logLevel: 4
metricsRelistInterval: 1m
listenPort: 6443
nodeSelector: {}
priorityClassName: ""
prometheus:
  url: http://prometheus-service.monitoring
  port: 9090
  path: ""
replicas: 1
rbac:
  create: true
serviceAccount:
  create: true
  name:
resources: {}
rules:
  default: true
  custom: []
  existing:
  external:
  - seriesQuery: 'grok_exporter_lines_matching_total{metric="workflows_threshold"}'
    resources:
      overrides:
        namespace:
          resource: namespace
    name:
      as: 'threshold_surpased'
    metricsQuery: 'increase(grok_exporter_lines_matching_total{metric="workflows_threshold"}[5m])'
  resource: {}
service:
  annotations: {}
  port: 443
  type: ClusterIP
tls:
  enable: false
  ca: |-
    # Public CA file that signed the APIService
  key: |-
    # Private key of the APIService
  certificate: |-
    # Public key of the APIService
extraVolumes: []
extraVolumeMounts: []
tolerations: []
podLabels: {}
podAnnotations: {}
hostNetwork:
  enabled: false
```

A simple custom rule is added to read the metric 'workflows_threshold' from the Prometheus container deployed with the SD-Prometheus [example](../helm/README.md#enable-metrics-and-display-them-in-prometheus-and-grafana).

Each rule in the adapter encodes four steps. Let's see each of them and how they are added to our rule in the configuration:

1. First, it discovers the metrics available

   We can add this to our rule in the 'seriesQuery' field, to tell the adapter how discover the right [series](https://prometheus.io/docs/concepts/data_model/) itself:

     seriesQuery: 'grok_exporter_lines_matching_total{metric="workflows_threshold"}'

2. We define what extra is added to the external metrics API

   we add the namespace to the external metric, that way the HPA will be able to find it as they will be in the same namespace

    resources:
      overrides:
        namespace:
          resource: namespace

3. We define how it should expose them to the external metrics API

   we define it as 'threshold_surpased'

    name:
      as: 'threshold_surpased'

4. Finally, we define how we should query Prometheus to get the actual value exposed to the API:

     metricsQuery: 'increase(grok_exporter_lines_matching_total{metric="workflows_threshold"}[5m])'

   the value returned in 'threshold_surpased' will be the increment of workflow warnings during the last 5 minutes. Therefore if the number of warnings decreases with the time the value will be 0


In order to deploy it we save the file as 'values.yaml' and we execute the following command from the same folder where it was saved:

     helm install promadapter stable/prometheus-adapter -f ./values.yaml

After some seconds the adapter is connected to the Promethues container and can be queried using this command:

    kubectl get --raw /apis/external.metrics.k8s.io/v1beta1


Finally we need to define an HPA with this metric exposed in the Kubernetes API:

```yaml
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: sd-workflows-hpa
  namespace: servicedirector
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: StatefulSet
    name: sd-cl
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: External
    external:
      metricName: threshold_surpased
      targetAverageValue: 0
```

we save the file as HPA.yaml and the following command will create a Horizontal Pod Autoscaler that maintains between 1 and 5 replicas of the sd-cl (CLosedLoop) Pods. We execute this command to deploy it :

    kubectl create -f HPA.yaml

The trigger will be the field 'targetAverageValue' which means it will take the average of the given metric (number of workflow threshold warnings increment in the last five minutes) across all sd-cl pods. The HPA will increase the number of sd-cl pods until the targetAverageValue is 0 (no increase in workflow warnings).

