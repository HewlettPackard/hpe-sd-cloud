# Service Director deployment in Kubernetes (k8s)

This directory holds Kubernetes cluster deployment sample specifications for Service Director. Current Kubernetes deployment samples include:

- [`sd-aio`](sd-aio): All-in-one k8s-deployment sample containing SD-Provisioning, SD-Closed-Loop and the UOC-based UI plus required databases for both (Oracle XE and CouchDB) in a single application/Pod.
- [`sd-sp`](sd-sp): SD Provisioning and Closed Loop k8s-deployment sample. An external database is required and for Closed Loop also Apache Kafka and Kafka-Zookeeper. Connection details will be made available to the container through environment variables.
- [`sd-ui`](sd-ui): UOC-based SD UI k8s-deployment sample. (CouchDB database is currently included inside the container). Details about the sd-sp instance to connect to will be made available through environment variables.
- [`sd-cl-adapter-snmp`](sd-cl-adapter-snmp): Service Director Closed Loop SNMP Adapter k8s-deployment sample. Details about the Kafka and Kafka-Zookeeper services to connect to will be made available through environment variables.

**NOTE** A prerequisites for any above deployments is a running kubernetes cluster
