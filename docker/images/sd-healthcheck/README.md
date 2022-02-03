# HPE SD health check

The `sd-healthcheck` image monitors the pods status after HPE SD is deployed using the Helm chart.

## Usage in Kubernetes versus other deployments

The `sd-healthcheck` image uses the Kubernetes REST API. Therefore, it can only be used in Kubernetes deployments.

## Deploying health check with the HPE SD Helm chart

The health check pod is optional in the HPE SD Helm chart.

Use this [link](../../../kubernetes/helm/charts#healthcheck-pod-for-service-director) to get information about activating and deploying the health check pod with the HPE SD Helm chart.
