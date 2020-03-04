SD UI Standalone Kubernetes deployment
=============================

This is a standalone Service Director UI Kubernetes (k8s) deployment, that will deploy the [sd-ui](/docker/images/sd-ui) container into a kubernetes cluster Pod. It includes UOC plus the Service Director UI plug-in. The required CouchDB database is embedded. When starting a container for the first time, Service Director UI will be configured creating the required database structures and configuration files. As such, an external SD-Provisioning instance is required to connect to (see [sd-sp-deployment](../sd-sp)).

Usage
-----

As before mentioned, the standalone Service Director UI application requires an external SD-Provisioning instance to connect to. Such instance may be also in a k8s deployment or just a regular one. If the target SD-Provisioning instance is deployed in same k8s using the [sd-sp-deployment.yaml](../sd-sp/sd-sp-deployment.yaml), the deployment environments variables in [sd-ui-deployment.yaml](sd-ui-deployment.yaml) are already set to work within that setup. Other than that, in order to point the SD-UI to the right SD-Provisioning instance you need to change the [sd-ui-deployment.yaml](sd-ui-deployment.yaml) to use specific connection variables when deploying the application, for example:

```yaml
env:
- name: SDCONF_sdui_async_host
  value: $(SDUI_NODEPORT_SERVICE_HOST)
- name: SDCONF_sdui_provision_host
  value: 172.17.0.1
- name: SDCONF_sdui_provision_password
  value: admin001
- name: SDCONF_sdui_provision_port
  value: 8080
- name: SDCONF_sdui_provision_protocol
  value: http
- name: SDCONF_sdui_provision_tenant
  value: UOC_SD
- name: SDCONF_sdui_provision_use_real_user
  value: "no"
- name: SDCONF_sdui_provision_username
  value: admin
- name: SDCONF_sdui_install_assurance
  value: "yes"
```

You can provide any variable supported by Service Director Ansible roles prefixed with `SDCONF_` within the sd-ui-deployment.yaml file.

**IMPORTANT**: The sd-ui-deployment.yaml file defines a docker registry example (hub.docker.hpecorp.net/cms-sd). This shall be changed to point to the docker registry where the sd-ui docker image is located: (`- image: hub.docker.hpecorp.net/cms-sd/sd-ui`)

**IMPORTANT**: Before deploying Service Director UI a namespace with the name "servicedirector" must be created. You have to deploy the file [namespace.yaml](../namespace.yaml) using the following command:

    kubectl create -f namespace.yaml

### Deploy CouchDB

HPE Service Director UI relies on CouchDB as its data persistence module, in order to deploy CouchDB we use a Helm Chart to easily bring up the services.

Follow the deployment as described in the [CouchDB](../../examples/couchdb) example before moving to the following part.

### Deploy Service Director UI

In order to deploy the standalone Service Director UI, run:

    kubectl create -f sd-ui-deployment.yaml

```
deployment.apps/sd-ui created
service/sd-ui-nodeport created
```

Validate when the deployed sdui application/pod is ready (READY 1/1)

    kubectl get pods --namespace servicedirector

```
NAME                        READY   STATUS    RESTARTS   AGE
sd-ui-8695c879f9-spx6x      1/1     Running   0          5m
```

When the application is ready, then the deployed service (SD User Interface) is exposed on the following url:

    http://<cluster_ip>:32515/login

**NOTE**: The kubernetes `cluster_ip` can be found using the `kubectl cluster-info`.

To delete the sdui deployment, run:

    kubectl delete -f sd-ui-deployment.yaml

```
deployment.apps "sd-ui" deleted
service "sd-ui-nodeport" deleted
```
