SD All-in-One Docker Image
==========================

This is an all-in-one Docker image for Service Director. It includes both provisioning (Service Activator plus the DDE solution), the closed loop (ASR solution, Kafka, Zookeeper and the SNMP adapter) and the UOC-based UI. Required databases for both Service Activator (EnterpriseDB) and UOC (CouchDB) are included as well.

Usage
-----

In order to start Service Director with Service Activator UI on port 8080, UOC on port 3000 and SNMP adapter listening on port 162 you can run

    docker run -p 8080:8080 -p 3000:3000 -p 162:162/udp sd-aio

As usual, you can specify `-d` to start the container in detached mode. Otherwise, you should see output like this:

```
    HPE
   _____                 _              ____  _                __
  / ___/___  ______   __(_)_______     / __ \(_)_______  _____/ /_____  _____
  \__ \/ _ \/ ___/ | / / / ___/ _ \   / / / / / ___/ _ \/ ___/ __/ __ \/ ___/
 ___/ /  __/ /   | |/ / / /__/  __/  / /_/ / / /  /  __/ /__/ /_/ /_/ / /
/____/\___/_/    |___/_/\___/\___/  /_____/_/_/   \___/\___/\__/\____/_/

Initializing EDB...
The files belonging to this database system will be owned by user "enterprisedb".
This user must also own the server process.

The database cluster will be initialized with locale "C".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /pgdata ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default timezone ... UTC
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
creating edb sys ... ok
loading edb contrib modules ...
edb_redwood_bytea.sql ok
edb_redwood_date.sql ok

[...]

syncing data to disk ... ok

Success. You can now start the database server using:

    /usr/edb/as11/bin/pg_ctl -D /pgdata -l logfile start

Starting EDB...
pg_ctl: server is running (PID: 169)
/usr/edb/as11/bin/edb-postgres "-D" "/pgdata"
Starting CouchDB...
Starting couchdb: [  OK  ]
Running Service Director configuration playbooks...

PLAY [localhost] ***************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

[...]

Starting Service Director...

Starting EDB...
pg_ctl: server is running (PID: 169)
/usr/edb/as11/bin/edb-postgres "-D" "/pgdata"
Starting CouchDB...
Starting couchdb: already running[WARNING]
Starting event collection framework...
Starting ZooKeeper daemon (zookeeper):
Starting Kafka daemon (kafka):
Starting Service Activator...
TRUNCATE TABLE
UPDATE 1

PLAY [localhost] ***************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

[...]

PLAY RECAP *********************************************************************
localhost                  : ok=5    changed=2    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

Waiting for CouchDB to be ready...
Starting UOC...
Starting UOC server on the port 3000 (with UOC2_HOME=/opt/uoc2)
Starting SNMP adapter...
Starting sd-asr-SNMPGenericAdapter_1

Service Director is now ready. Displaying Service Activator log...
```

Once SD has finished booting you will see a live SA `$JBOSS_HOME/standalone/log/server.log` until the container is stopped.

If you stop and then start the container again you will see a similar output just without the preparation part as this only needs to be done on the first run. There is also an option when building the image to have it prepared at build time so first run is faster. This poses no problem at all since everything is in the same container here.

If you want to get a shell into the container, you can run

    docker exec -it <container_name> /bin/bash

while it is running. If you want to log into the container while it is stopped, you can run

    docker start -i <container_name> /bin/bash

instead. You can also try [Portainer](https://portainer.io), a management UI for Docker which among other things allows you to open a console session into any running container.

Building
--------

This image is based on `sd-base-ansible` so you will need to build that one first.

In order to ease building a build-wrapper script `build.sh` script is provided. This script will build the image and tag it as `sd-aio`.

Building this image also requires the correspoding Service Director ISO to be mounted/extracted into the `iso` directory.

In order to build the image behind a corporate proxy it is necessary to define the appropriate proxy environment variables. Such variables are specified by default by the build-wrapper script. In order to use a different proxy just define them as appropriate in your environment.

The image can be built in two different ways:

- Non-prepared (default): This means software is installed into the image but some tasks need to be performed upon first startup of the container. These tasks include database creation, configuration of SA & UOC and deployment of the DDE solution. This approach has some advantages:
    - The resulting image is lighter
    - This structure is the same which will be used for production images as we won't know about the database at build time. In this case however we do.
- Prepared: This means the image is ready to start, database instances are already created and everything is deployed. This approach has the advantage of a faster container instantiation, but results in a heavier image.

In order to specify whether the image should be prepared at build time or not, you can set the `PREPARED` environment variable to either `true` (default) or `false`. You can also specify whether the resulting image should be squashed to save up disk space or not by setting the `SQUASH` environment variable. Note however that in order to squash images you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information check the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

This all-in-one image includes an EnterpriseDB database which needs to be installed as part of the image-building procedure. It is installed from EnterpriseDB Yum repositories, which require authentication. So in order to build the image yourself you will need to specify valid credentials ([request access](https://www.enterprisedb.com/repository-access-request?destination=node/1255704&resource=1255704&ma_formid=2098)) through environment variables `EDB_YUM_USERNAME` and `EDB_YUM_PASSWORD`. If they are missing the build-wrapper script will stop and inform you about the fact.

So e.g. if you want to build an squashed, prepared image and your credentials are `foo`/`bar`, you would run:

```sh
SQUASH=true EDB_YUM_USERNAME=foo EDB_YUM_PASSWORD=bar ./build.sh
```

If you want to build the image by hand, you can use the following:

    docker build -t sd-aio \
        --build-arg EDB_YUM_USERNAME=foo \
        --build-arg EDB_YUM_PASSWORD=bar \
        .

or if you are behind a corporate proxy:

    docker build -t sd-aio \
        --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
        --build-arg http_proxy=http://your.proxy.server:8080 \
        --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
        --build-arg https_proxy=http://your.proxy.server:8080 \
        --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
        --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
        --build-arg EDB_YUM_USERNAME=foo \
        --build-arg EDB_YUM_PASSWORD=bar \
        .

If you want a non-prepared image you can set `prepared=false`:

    docker build -t sd-aio \
        --build-arg prepared=false \
        .

Technical Details
-----------------

Apart from what is described in the `Dockerfile` this build includes some shell scripts:

- `configure_edb.sh`: this script configures EnterpriseDB and creates the database and database user. It may be run during the build phase (prepared build) or upon first start of the container.
- `configure_sd.sh`: this script configures Service Director components using Ansible roles. It may be run during the build phase (prepared build) or upon first start of the container.
- `start_edb.sh`: this script takes care of starting EnterpriseDB. It handles hostname changes which occur in prepared images as the database is configured during the build phase with a certain container id and then the hostname for the final container is different.
- `startup.sh`: this script is the container entry point. It will execute the configuration scripts if found (meaning that they have not been executed before) and then remove them (so they are not executed again). Then it starts EnterpriseDB, CouchDB, Kafka, Zookeeper, the SNMP adapter, Service Activator and UOC. Finally it will tail `$JBOSS_HOME/standalone/log/server.log` until the container is stopped, at this point the script should recive a `SIGTERM` which will cause it to stop all previously started services. Note that Docker has a grace period of 10 seconds when stopping containers, after which it will send a `SIGKILL`. It might be the case that 10s is not long enough for Service Activator to stop, in order to give it some more time you can use the `-t` argument when stopping the container, e.g. `docker stop -t 120` to give it 120s.

Other details worth mentioning:

- Not everything in the ISO is relevant for building the image, so some paths are omitted from the context in order to reduce build time and image weight (see `.dockerignore`). Anyway since part of the ISO contents need to be copied into the image just for installation it will be heavier than it should be. This space can be recovered by squashing the image as the installation packages are removed later.
- When starting Activator's WildFly inside the Docker container we were facing a `java.net.SocketException: Protocol family unavailable`. This seems to be due to IPv6 not being available inside the container, probably because it needs to be enabled (see https://docs.docker.com/config/daemon/ipv6/). What we have done is adding `-Djava.net.preferIPv4Stack=true` as an extra option for the JVM invocation in `standalone.conf` to force using IPv4.
- When the image is prepared at build time, the build-time hostname is different to the run-time one. So when `ActivatorConfig` is run during the build phase the build-time hostname is inserted into the `CLUSTERNODELIST` database table. In order to fix this, before starting SA the table must be updated with the new container hostname. As there is a FK from `MODULES`, it is truncated first (module entries are recreated automatically).
