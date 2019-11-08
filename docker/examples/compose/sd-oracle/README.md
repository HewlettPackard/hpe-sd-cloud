# Service Director Alternative Database Scenario: Oracle

This compose file is an example of how to use an Oracle database for Service Activator instead of EnterpriseDB as shown in other examples. For the purpose of this example we are bringing up an instance of the `oracledb-18xe-sa` image, which is basically a clean Oracle XE 18c image with an `hpsa` user ready for Service Activator installation. You can find the `Dockerfile` for building this database image in the [examples/images/oracledb-18xe-sa](/docker/examples/images/oracledb-18xe-sa) directory. For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Oracle's [docker-images](https://github.com/oracle/docker-images).

So, this compose file contains the following services:

- `db`: fulfillment database server
- `sp`: provisioning node

The following ports are exposed:

- `8080`: Service Activator native UI

Note this example does not include an SD UI container since it is not relevant here.

In order to guarantee that services are started in the right order, this compose file makes use of the health check feature. This was added in compose file format 2.1 but has not made it into 3.x so this is the cause we are sticking with 2.x, with version 2.4 being the latest at the time of this writing. All official Service Director Docker images support health check, and the `oracledb-18xe-sa` image included here as an example supports it as well. If you provide your own database image you need to make sure it supports health check properly so as to avoid starting provisioning containers before the database is ready to accept connections. If you are using an external database, you may remove the `db` service and adjust `SDCONF_activator_db_`-prefixed variables as appropriate, also you need to make sure that your database is ready to accept connections before bringing the compose up.

In order to bring the compose up, you just need to run `docker-compose up` from this directory.
