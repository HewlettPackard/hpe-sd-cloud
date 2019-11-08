# Service Director Closed-Loop High Availability Scenario

This compose file defines a standard Service Director high availability configuration with two provisioning nodes, two pure closed-loop backend nodes, an SNMP adapter and the UOC-based UI.

As Service Activator requires an external database as well, for the purpose of this example we using `containers.enterprisedb.com/edb/edb-as-lite:v11` which you can pull from EnterpriseDB container repository ([request access here](https://www.enterprisedb.com/repository-access-request?destination=node/1255704&resource=1255704&ma_formid=2098)). You can find an example using an Oracle database instead in [sd-oracle](../sd-oracle). For production environments you should either use an external, non-containerized database or create an image of your own.

Finally the closed looks also requires a Kafka/Zookeeper cluster, and for that purpose we are using images `bitnami/kafka` and `bitnami/zookeeper` which are available on Docker Hub.

So, this compose file contains the following services:

- `db`: fulfillment database server
- `sp-prov`: primary provisioning node
- `sp-prov2`: additional provisioning node
- `sp-asr`: primary closed-loop node
- `sp-asr2`: additional closed-loop node
- `ui`: UOC-based UI
- `snmpadapter`: SNMP adapter
- `kafka[1-3]`: Kafka nodes
- `zookeeper[1-3]`: Zookeeper nodes

The following ports are exposed:

- `8081`: Service Activator native UI (primary provisioning node)
- `8082`: Service Activator native UI (additional provisioning node)
- `8083`: Service Activator native UI (primary closed-loop node)
- `8084`: Service Activator native UI (additional closed-loop node)
- `162` (UDP): SNMP adapter

In order to guarantee services are started in the right order, this compose file makes use of the health check feature. This was added in compose file format 2.1 but has not made it into 3.x so this is the cause we are sticking with 2.x, with version 2.4 being the latest at the time of this writing. All official Service Director Docker images support health check, and for the database container we are defining one directly on the compose file. If you provide your own database image you need to make sure it supports health check properly or otherwise define a health check in the compose file as well so as to avoid starting provisioning containers before the database is ready to accept connections. If you are using an external database, you may remove the `db` service and adjust `SDCONF_activator_db_`-prefixed variables as appropriate, also you need to make sure that your database is ready to accept connections before bringing the compose up.

The example includes configuration of bind mounts for accessing logs from the host machine. In order to avoid trouble with permissions if you are running `docker-compose` as a non-root user (containers run as root), you may want to create log directories beforehand and adjust permissions for them:

    mkdir -p -m 777 logs/sp-{prov,asr}{,2}/{activator,wildfly} logs/ui/{uoc,couchdb}

If you don't need direct access to log directories you can remove `volumes:` sections in the `docker-compose.yml` file.

In order to bring the compose up, you just need to run `docker-compose up` from this directory.