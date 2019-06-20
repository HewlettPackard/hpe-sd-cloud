SD All-in-One Docker Image (Service Provisioner only)
=====================================================

This is an all-in-one Docker image for Service Director. It includes both provisioning (Service Activator plus the DDE solution) and the UOC-based UI. Required databases for both Service Activator (Oracle XE) and UOC (CouchDB) are included as well. As opposed to the `sd-aio` image, this one does not include closed-loop.

Usage
-----

In order to start Service Director with Service Activator UI on port 8081 and UOC on port 3000 you can run

    docker run -p 8081:8081 -p 3000:3000 sd-aio-sp

As usual, you can specify `-d` to start the container in detached mode. Otherwise, you should see output like this:

```
    HPE
   _____                 _              ____  _                __
  / ___/___  ______   __(_)_______     / __ \(_)_______  _____/ /_____  _____
  \__ \/ _ \/ ___/ | / / / ___/ _ \   / / / / / ___/ _ \/ ___/ __/ __ \/ ___/
 ___/ /  __/ /   | |/ / / /__/  __/  / /_/ / / /  /  __/ /__/ /_/ /_/ / /
/____/\___/_/    |___/_/\___/\___/  /_____/_/_/   \___/\___/\__/\____/_/

Starting Service Director...

Starting Oracle XE...
Starting Oracle Net Listener.
Starting Oracle Database 11g Express Edition instance.

Starting CouchDB...
Starting database server couchdb
Starting SA...

Table truncated.


1 row updated.

Start HPE Service Activator daemon
Starting HPE Service Activator application server
Waiting for CouchDB to be ready....
Starting UOC...
Starting UOC server on the port 3000 (with UOC2_HOME=/opt/uoc2)

Service Director is now ready. Showing Service Activator log...

2018-07-16 12:54:21,650 INFO  [stdout] (Thread-113) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: workflow 'NNMi_ExecWF' loaded
2018-07-16 12:54:21,660 INFO  [stdout] (Thread-113) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: workflow 'NNMi_addSeed' loaded
2018-07-16 12:54:21,670 INFO  [stdout] (Thread-113) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: workflow 'NNMi_setNode_OUTOFSERVICE' loaded
2018-07-16 12:54:21,673 INFO  [stdout] (Thread-113) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: workflow 'send_message_OUTOFSERVICE' loaded
2018-07-16 12:54:21,674 INFO  [stdout] (Thread-113) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: Asking for workflow lock
2018-07-16 12:54:21,674 INFO  [stdout] (keep_alive module thread) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: Workflows load thread notify caller thread.
2018-07-16 12:54:21,674 INFO  [stdout] (keep_alive module thread) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: Calling distribution load of workflows done.
2018-07-16 12:54:21,677 INFO  [stdout] (Thread-113) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: Got workflow lock
2018-07-16 12:54:21,680 INFO  [stdout] (keep_alive module thread) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: Commit done.
2018-07-16 12:54:21,680 INFO  [stdout] (keep_alive module thread) Jul 16, 2018 12:54:21 PM [Plug-in standard output]: Loading and validating all workflows from the database finished (distributed).
```

Once SD has finished booting you will see a live SA `$JBOSS_HOME/standalone/log/server.log` until the container is stopped.

If you stop and then start the container again you will see a similar output just without the preparation part as this only needs to be done on the first run. There is also an option when building the image to have it prepared at build time so first run is faster. This poses no problem at all since everything is in the same container here.

If you want to get a shell into the container, you can run

    docker exec -it <container_name> /bin/bash

while it is running. If you want to log into the container while it is stopped, you can run

    docker start -i <container_name> /bin/bash

instead. You can also try [Portainer](https://portainer.io), a management UI for Docker which among other things allows you to open a console session into any running container.

If you find issues running this image, particularly when creating the fulfillment database, you may want to try specifying `--shm-size=1g` in the command line in order to set a shared memory size of 1G (default for Docker containers is 64M). On some systems this seems to be required whereas in others this is not necessary.

Building
--------

This image is based on `sd-base-ansible` so you will need to build that one first.

Building this image requires some third party RPM packages which are not included in this repository. Such files are listed in `distfiles` along with their SHA-1 sum and a URL from where they can be downloaded when available so the build script can verify them and in some cases download them automatically. You can find a table listing such files below:

| Path | Obtain from |
| - | - |
| `kits/oracle-database-xe-18c-1.0-1.x86_64.rpm` | [Oracle download](https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html) (unzip) |

In order to ease building a build-wrapper script `build.sh` script is provided. This script will:

- Ensure that all required files are present and match expected SHA-1 hashes
- Fetch missing files from several sources:
    - For `http[s]://` prefixed URLs, `curl` will be used to fetch from the Internet/intranet
- Build the image and tag it as `sd-aio-sp`.

Building this image also requires the correspoding Service Director ISO to be mounted/extracted into the `iso` directory.

In order to build the image behind a corporate proxy it is necessary to define the appropriate proxy environment variables. Such variables are specified by default by the build-wrapper script. In order to use a different proxy just define them as appropriate in your environment.

The image can be built in two different ways:

- Non-prepared (default): This means software is installed into the image but some tasks need to be performed upon first startup of the container. These tasks include database creation, configuration of SA & UOC and deployment of the DDE solution. This approach has some advantages:
    - The resulting image is lighter
    - This structure is the same which will be used for production images as we won't know about the database at build time. In this case however we do.
- Prepared: This means the image is ready to start, database instances are already created and everything is deployed. This approach has the advantage of a faster container instantiation, but results in a heavier image.

In order to specify whether the image should be prepared at build time or not, you can set the `PREPARED` environment variable to either `true` or `false`. You can also specify whether the resulting image should be squashed to save up disk space or not by setting the `SQUASH` environment variable. Note however that in order to squash images you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information check the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

If you want to build the image by hand, you can use the following:

    docker build -t sd-aio-sp \
        --build-arg prepared=false \
        .

or if you are behind a corporate proxy:

    docker build -t sd-aio-sp \
        --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
        --build-arg http_proxy=http://your.proxy.server:8080 \
        --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
        --build-arg https_proxy=http://your.proxy.server:8080 \
        --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
        --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
        --build-arg prepared=false \
        .

If you want a prepared image you can set `prepared=true`:

    docker build -t sd-aio-sp \
        --build-arg prepared=true \
        .

Anyway if you build by hand remember that you need to make sure that you have all the files listed in `distfiles` in place, otherwise the build will fail.

Technical Details
-----------------

Apart from what is described in the `Dockerfile` this build includes some shell scripts:

- `configure_oraclexe.sh`: this script configures Oracle XE and creates the database instance. It may be run during the build phase (prepared build) or upon first start of the container.
- `configure_sd.sh`: this script configures Service Director components using Ansible roles. It may be run during the build phase (prepared build) or upon first start of the container.
- `start_oraclexe.sh`: this script takes care of starting Oracle XE. It handles hostname changes which occur in prepared images as the database is configured during the build phase with a certain container id and then the hostname for the final container is different.
- `startup.sh`: this script is the container entry point. It will execute the configuration scripts if found (meaning that they have not been executed before) and then remove them (so they are not executed again). Then it starts Oracle and CouchDB, and then Service Activator and UOC. Finally it will tail `$JBOSS_HOME/standalone/log/server.log` until the container is stopped, at this point the script should recive a `SIGTERM` which will cause it to stop all previously started services. Note that Docker has a grace period of 10 seconds when stopping containers, after which it will send a `SIGKILL`. It might be the case that 10s is not long enough for Service Activator to stop, in order to give it some more time you can use the `-t` argument when stopping the container, e.g. `docker stop -t 120` to give it 120s.

Other details worth mentioning:

- Specific inventories and playbooks for Docker are not included in product Ansibles for now so they are instead in here. So when building the image roles are copied from the ISO and then inventories and playbooks are copied from the `assets/ansible` directory.
- Not everything in the ISO is relevant for building the image, so some paths are omitted from the context in order to reduce build time and image weight (see `.dockerignore`). Anyway since part of the ISO contents need to be copied into the image it will be heavier than it should be.
- When starting Activator's WildFly inside the Docker container we were facing a `java.net.SocketException: Protocol family unavailable`. This seems to be due to IPv6 not being available inside the container, probably because it needs to be enabled (see https://docs.docker.com/config/daemon/ipv6/). What we have done is adding `-Djava.net.preferIPv4Stack=true` as an extra option for the JVM invocation in `standalone.conf` to force using IPv4.
- When the image is prepared at build time, the build-time hostname is different to the run-time one. So when `ActivatorConfig` is run during the build phase the build-time hostname is inserted into the `CLUSTERNODELIST` database table. In order to fix this, before starting SA the table must be updated with the new container hostname. As there is a FK from `MODULES`, it is truncated first (module entries are recreated automatically).
