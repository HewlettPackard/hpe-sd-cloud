# Service Director examples in Kubernetes (K8S)
This directory contains databases examples and holds an all-in-one Kubernetes (K8S) deployment for Service Director with demo purposes.

**NOTE** For production environments you should either use an external, non-containerized database or create an image of your own.

You can find the following subdirectories:

- [postgres-db](postgres-db): Includes an postgres-db K8S deployment example for supporting the SD K8S deployment.

- [enterprise-db](enterprise-db): Includes an enterprise-db K8S deployment example for supporting the SD K8S deployment.

- [oracle-db](oracle-db): Includes an oracle-db K8S deployment example for supporting the SD K8S deployment.

- [sd-aio](sd-aio): All-in-one K8S-deployment sample containing SD-Provisioning, SD-Closed-Loop and the UOC-based UI plus required databases for both (PostgreSQL and CouchDB) in a single application/Pod.

**NOTE** A prerequisites for any above deployments is a running kubernetes cluster.
