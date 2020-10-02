# Service Director deployment in Kubernetes (K8S)

This directory contains several examples which can give you some ideas about how to leverage Service Director (SD) into a kubernetes cluster for development, testing, demo and even production scenarios.

You can find the following subdirectories:

- [Auto Scaling](./AutoScaling.md): The Horizontal Pod Autoscaler automatically scales the number of Pods in a replication controller, deployment, replica set or stateful set based on observed CPU utilization.

- [Grafana](./Grafana.md): Describe Grafana dashboards included in the Helm example.

- [Istio](./Istio.md): Istio is an implementation of a service mesh and provides several services.

- [Persistent Volumes](./PersistentVolumes.md): The `PersistentVolume` (PV) object abstracts details of how storage is provided in a Kubernetes cluster.

- [Resources](./Resources.md): Resources (CPU, memory, disc size) configuration.

- [Scaling Best Practices](./ScalingBestPractices.md): Describe scaling best practices.

- [alertmanager](./alertmanager): Configure Service Director alerts in Prometheus.

- [elastalert](./elastalert): Configure Service Director alerts in ELK.
