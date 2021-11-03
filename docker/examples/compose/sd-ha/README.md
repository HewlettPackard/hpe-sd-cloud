# Service Director High Availability Scenario

This compose file defines a standard Service Director high availability configuration with two provisioning nodes and the UOC-based UI as well.

As Service Activator requires an external database as well, for the purpose of this example we are using `postgres:13-alpine` for a PostgreSQL 13 database. You can find an example using an Oracle database instead in [sd-oracle](../sd-oracle). For production environments you should either use an external, non-containerized database or create an image of your own.

So, this compose file contains the following services:

- `db`: fulfillment database server
- `sp`: primary provisioning node
- `sp-extra`: additional provisioning node
- `ui`: UOC-based UI
- `couchdb`: CouchDB database

The following ports are exposed:

- `8081`: Service Activator native UI (primary node)
- `8082`: Service Activator native UI (additional node)
- `3000`: Unified OSS Console (UOC)

The example includes configuration of bind mounts for accessing logs directory from the host machine. In order to avoid trouble with permissions, you may want to create log directories beforehand and adjust permissions for them:

    mkdir -p -m 777 logs/sp/{wildfly,activator} logs/ui/{uoc,couchdb}

If you don't need direct access to log directories you can remove `volumes:` sections in the `docker-compose.yml` file.

In order to bring the compose up, you just need to run `docker-compose up` from this directory.
