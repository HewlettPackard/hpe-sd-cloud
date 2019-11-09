# Service Director on Docker Containers

This directory holds several specifications for building Docker images for Service Director containers. Current images include:

- [`sd-aio`](sd-aio): All-in-one image containing provisioning, the closed loop (incl. Kafka and Zookeeper) and the UOC-based UI plus required databases (EnterpriseDB and CouchDB).
- [`sd-sp`](sd-sp): SD Provisioning container. An external database is required, connection details will be made available to the container through environment variables.
- [`sd-ui`](sd-ui): UOC-based SD UI container. Details about the SP instance to connect to will be made available to the container through environment variables.
- [`sd-cl-adapter-snmp`](sd-cl-adapter-snmp): SNMP adapter.
- [`sd-base-ansible`](sd-base-ansible): Base image serving as the foundation for all Ansible-based Service Director images. It is based on [`centos:7`](https://hub.docker.com/_/centos/) and includes Ansible plus Python modules required by Ansible modules being used in SD roles plus some dependencies common to all images.
- [`sa`](sa): Pure Service Activator container. An external database is required, connection details will be made available to the container through environment variables.

Currently the approach is to leverage the Ansible roles included in the SD ISO for building the images and also when configuring the container upon first startup.
