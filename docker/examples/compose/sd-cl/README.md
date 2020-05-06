# Service Director Closed-Loop High Availability Scenario

This compose file defines a standard Service Director high availability configuration with two Service Activator cluster nodes, an SNMP adapter and the UOC-based UI.

Service Activator requires an external database instance and a CouchDB instance to connect to. For the purpose of this example we using `containers.enterprisedb.com/edb/edb-as-lite:v11` which you can pull from EnterpriseDB container repository ([request access here](https://www.enterprisedb.com/repository-access-request?destination=node/1255704&resource=1255704&ma_formid=2098)). You can find an example using an Oracle database instead in [sd-oracle](../sd-oracle). If you prefer PostgreSQL, you can take a look at the [sa-ha](../sa-ha) example for Service Activator. For production environments you should either use an external, non-containerized database or create an image of your own.

**Note:** in order to properly configure EnterpriseDB, a volume is monted at `/initconf` with a `postgresql.conf.in` file containing specific configuration.

Finally the closed loop also requires a Kafka/Zookeeper cluster, and for that purpose we are using images `bitnami/kafka` and `bitnami/zookeeper` which are available on Docker Hub. In the examples the Kafka > Zookeeper connection timeout is set to a quite high value of 60s because in some constrained test/demo environments (like a laptop) Zookeeper does not start fast enough sometimes and that will cause Kafka containers to fail. For production environments probably you will want to remove the `KAFKA_CFG_ZOOKEEPER_CONNECTION_TIMEOUT_MS` variable to use the default of 18s or set it to another value according to your evironment. In the other hand if your Kafka containers are still failing due to connection timeouts you may want to raise the value even more.

So, this compose file contains the following services:

- `db`: fulfillment database server
- `sp`: primary provisioning node
- `sp-extra`: additional provisioning node
- `ui`: UOC-based UI
- `snmpadapter`: SNMP adapter
- `kafka[1-3]`: Kafka nodes
- `zookeeper[1-3]`: Zookeeper nodes
- `couchdb`: CouchDB database

The following ports are exposed:

- `8081`: Service Activator native UI (primary node)
- `8082`: Service Activator native UI (additional node)
- `162` (UDP): SNMP adapter

The example includes configuration of bind mounts for accessing logs from the host machine. In order to avoid trouble with permissions if you are running `docker-compose` as a non-root user (containers run as root), you may want to create log directories beforehand and adjust permissions for them:

    mkdir -p -m 777 logs/sp{,-extra}/{activator,wildfly} logs/ui/{uoc,couchdb}

If you don't need direct access to log directories you can remove `volumes:` sections in the `docker-compose.yml` file.

In order to bring the compose up, you just need to run `docker-compose up` from this directory.
