# Service Director High Availability Scenario

This compose file defines a standard Service Director high availability configuration with two provisioning nodes and the UOC-based UI as well.

As Service Activator requires an external database as well, for the purpose of this example we are bringing up an instance of the `oracledb-sa:11.2.0.2-xe` image, which is basically a clean Oracle XE 11g image with an `hpsa` user ready for Service Activator installation. You can find the `Dockerfile` for building this database image in the [examples/images/oracledb-sa](/docker/examples/images/oracledb-sa) directory. For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Oracle's [docker-images](https://github.com/oracle/docker-images).

So, this compose file contains the following services:

- `db`: fulfillment database server
- `sp`: primary provisioning node
- `sp-extra`: additional provisioning node
- `ui`: UOC-based UI

The following ports are exposed:

- `8081`: Service Activator native UI (primary node)
- `8082`: Service Activator native UI (additional node)
- `3000`: Unified OSS Console (UOC)

In order to guarantee that services are started in the right order, this compose file makes use of the health check feature. This was added in compose file format 2.1 but has not made it into 3.x so this is the cause we are sticking with 2.x, with version 2.4 being the latest at the time of this writing. All official Service Director Docker images support health check, and the `oracledb-sa:11.2.0.2-xe` image included here as an example supports it as well. If you provide your own database image you need to make sure it supports health check properly so as to avoid starting provisioning containers before the database is ready to accept connections. If you are using an external database, you may remove the `db` service and adjust `SDCONF_hpsa_db_`-prefixed variables as appropriate, also you need to make sure that your database is ready to accept connections before bringing the compose up.

The example includes configuration of bind mounts for accessing logs directory from the host machine. In order to avoid trouble with permissions, you may want to create log directories beforehand and adjust permissions for them:

    mkdir -p -m 777 logs/sp/{wildfly,activator} logs/ui/{uoc,couchdb}

If you don't need direct access to log directories you can remove `volumes:` sections in the `docker-compose.yml` file.

In order to bring the compose up, you just need to run `docker-compose up` from this directory.