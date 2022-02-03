# HPE Service Director on Docker containers

This directory holds several specifications for building Docker images for HPE Service Director containers. Current images include:

- [`sd-aio`](sd-aio): All-in-one image containing HPE SD Provisioning, HPE SD Closed Loop (including Kafka and Zookeeper), the HPE UOC-based HPE SD Operational UI, and the required databases (PostgreSQL and CouchDB).
- [`sd-sp`](sd-sp): HPE SD Provisioning container. An external database is required. When you instantiate the container, you must specify connection details through environment variables.
- [`sd-ui`](sd-ui): The HPE UOC-based HPE SD Operational UI container. When you instantiate the container, you must specify connection details through environment variables.
- [`sd-cl-adapter-snmp`](sd-cl-adapter-snmp): SNMP adapter.
- [`sd-healthcheck`](sd-healthcheck): Healthcheck container used to monitor the HPE SD helm chart deployment.
- [`sd-base-ansible`](sd-base-ansible): Base image serving as the foundation for all Ansible-based HPE SD images. It is based on [`almalinux:8`](https://hub.docker.com/_/almalinux) and includes Ansible plus Python modules required by Ansible modules used in HPE SD roles plus some dependencies common to all images.
- [`sa`](sa): Pure HPE Service Activator container. An external database is required. When you instantiate the container, you must specify connection details through environment variables.

