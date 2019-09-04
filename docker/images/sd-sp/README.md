SD Provisioning Image
============================

This is a standalone SD Provisioning image. It includes Service Activator plus DDE and additional solutions. An external database is required. When starting a container for the first time, Service Activator will be configured creating the required database structure (if it is the first node of the cluster) or adding itself to an existing SA cluster.

Usage
-----

As before mentioned, the standalone provisioning container requires an external database instance. Such database instance may be also in a container or just a regular one. If the target database is in a container you will need to make sure they are in the same network. Other than that, in order to point the container to the right database instance you need to specify some environment variables when instantiating the container, for example:

    SDCONF_hpsa_db_vendor=Oracle
    SDCONF_hpsa_db_hostname=172.17.0.3
    SDCONF_hpsa_db_instance=XE
    SDCONF_hpsa_db_user=hpsa
    SDCONF_hpsa_db_password=secret

If you are connecting to an EnterpriseDB Postgres database then just set `SDCONF_hpsa_db_vendor=EnterpriseDB`.

If you want the container to act as a closed-loop backend node, you need to specify some additional variables:

    SDCONF_enable_cl=yes
    SDCONF_asr_kafka_brokers=kafka1:9092,kafka2:9092,kafka3:9092
    SDCONF_asr_zookeeper_nodes=zookeeper1:2181,zookeeper2:2181,zookeeper3:2181

Additionally, if you want the node to act as a pure closed-loop node, without the provisioning part, you can specify

    SDCONF_enable_provisioning=no

When setting up a cluster with multiple nodes, you need to specify the following variable on all nodes but the first one:

    SDCONF_hpsa_db_create=no

You can provide any variable supported by Service Director Ansible roles prefixed with `SDCONF_`. In order to pass environment variables to the docker container you can use either the `-e` command-line option, e.g. `-e SDCONF_oracle_hostname=172.17.0.1` or use `--env-file` along with a file containing a list of environment variables e.g. `--env-file=config.env`. You can find an example of such environment file in [`example.env`](example.env). For more information check the [official documentation on the `docker run` command](https://docs.docker.com/engine/reference/commandline/run/).

Note that the specified database user must already exist and, in case you are creating the first node of a cluster, it must be empty.

So in order to start a provisioning container on port 8081 you can run e.g.

    docker run --env-file=config.env -p 8081:8081 sd-sp

By default, a 30-day Instant On license will be used. If you have a license file, you can supply it by bind-mounting it at `/license`, like this:

    docker run --env-file=config.env -v /path/to/license.dat:/license -p 8081:8081 sd-sp

As usual, you can specify `-d` to start the container in detached mode. Otherwise, you should see output like this:

```
    HPE
   _____                 _              ____  _                __
  / ___/___  ______   __(_)_______     / __ \(_)_______  _____/ /_____  _____
  \__ \/ _ \/ ___/ | / / / ___/ _ \   / / / / / ___/ _ \/ ___/ __/ __ \/ ___/
 ___/ /  __/ /   | |/ / / /__/  __/  / /_/ / / /  /  __/ /__/ /_/ /_/ / /
/____/\___/_/    |___/_/\___/\___/  /_____/_/_/   \___/\___/\__/\____/_/

Configuring Service Director...

Running configuration playbook...
ansible-playbook 2.6.0
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/root/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/site-packages/ansible
  executable location = /usr/bin/ansible-playbook
  python version = 2.7.5 (default, Apr 11 2018, 07:36:10) [GCC 4.8.5 20150623 (Red Hat 4.8.5-28)]
Using /etc/ansible/ansible.cfg as config file
setting up inventory plugins
Set default localhost to localhost
Parsed /docker/ansible/inventories/provisioning-orcl/hosts inventory source with ini plugin
 [WARNING]: While constructing a mapping from /docker/ansible/roles/ansible-
role-serviceactivator-config/defaults/main.yml, line 3, column 1, found a
duplicate dict key (webserver_port). Using last defined value only.
Loading callback plugin default of type stdout, v2.0 from /usr/lib/python2.7/site-packages/ansible/plugins/callback/default.pyc

PLAYBOOK: sp_configure.yml *****************************************************
1 plays in sp_configure.yml

PLAY [primaryprovisioningserver] ***********************************************

TASK [Gathering Facts] *********************************************************

[...]
```

Then once configuration is finished you should see something like this:

```
PLAY RECAP *********************************************************************
localhost                  : ok=34   changed=24   unreachable=0    failed=0

Starting Service Activator...

Start HPE Service Activator daemon
Starting HPE Service Activator application server

Service Activator is now ready. Displaying log...

2018-07-18 11:03:35,395 INFO  [org.jboss.modules] (main) JBoss Modules version 1.4.3.Final
2018-07-18 11:03:35,594 INFO  [org.jboss.msc] (main) JBoss MSC version 1.2.6.Final
2018-07-18 11:03:35,664 INFO  [org.jboss.as] (MSC service thread 1-7) WFLYSRV0049: WildFly Full 9.0.2.Final (WildFly Core 1.0.2.Final) starting

[...]

2018-07-18 11:03:51,193 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Full 9.0.2.Final (WildFly Core 1.0.2.Final) started in 16136ms - Started 1666 of 1862 services (256 services are lazy, passive or on-demand)
```

Once Service Activator is done booting you will see a live `$JBOSS_HOME/standalone/log/server.log` until the container is stopped.

If you stop and then start the container again you will see a similar output just without the configuration part as this only needs to be done during the first run.

If you want to get a shell into the container, you can run

    docker exec -it <container_name> /bin/bash

while it is running. If you want to log into the container while it is stopped, you can run

    docker start -i <container_name> /bin/bash

instead. You can also try [Portainer](https://portainer.io), a management UI for Docker which among other things allows you to open a console session into any running container.

Building
--------

This image is based on `sd-base-ansible` so you will need to build that one first.

In order to ease building a build-wrapper script `build.sh` script is provided. This script will:

- Ensure that all required files are present and match expected SHA-1 hashes
- Fetch missing files from several sources:
    - For `http[s]://` prefixed URLs, curl will be used to fetch from the Internet/intranet
- Build the image and tag it as `sd-sp`.

Building this image also requires the correspoding Service Director ISO to be mounted/extracted into the `iso` directory.

In order to build the image behind a corporate proxy it is necessary to define the appropriate proxy environment variables. Such variables are specified by default by the build-wrapper script. In order to use a different proxy just define them as appropriate in your environment.

You can also specify whether the resulting image should be squashed to save up disk space or not by setting the `SQUASH` environment variable to either `true` or `false`. Note however that in order to squash images you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information check the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

If you want to build the image by hand, you can use the following:

    docker build -t sd-sp .

or if you are behind a proxy:

    docker build -t sd-sp \
        --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
        --build-arg http_proxy=http://your.proxy.server:8080 \
        --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
        --build-arg https_proxy=http://your.proxy.server:8080 \
        --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
        --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
        .

Technical Details
-----------------

Apart from what is described in the `Dockerfile` this build includes a couple shell scripts:

- `configure_sp.sh`: this script configures SD Provisioning using Ansible roles, including configuration of Service Activator and deployment of DDE and additional solutions.
- `startup.sh`: this script is the container entry point. It will execute the configuration scripts if found (meaning that they have not been executed before) and then remove them (so they are not executed again). Then it starts Service Activator. Finally it will tail `$JBOSS_HOME/standalone/log/server.log` until the container is stopped, at this point the script should recive a `SIGTERM` which will cause it to stop all previously started services. Note that Docker has a grace period of 10 seconds when stopping containers, after which it will send a `SIGKILL`. It might be the case that 10s is not long enough for Service Activator to stop, in order to give it some more time you can use the `-t` argument when stopping the container, e.g. `docker stop -t 120` to give it 120s.

Other details worth mentioning:

- Specific inventories and playbooks for Docker are not included in product Ansibles for now so they are instead in here. So when building the image roles are copied from the ISO/product Ansible repository and then inventories and playbooks are copied from the `assets/ansible` directory.
- Not everything in the ISO is relevant for building the image, so some paths are omitted from the context in order to reduce build time and image weight (see `.dockerignore`). Anyway since part of the ISO contents need to be copied into the image it will be heavier than it should be.
- When starting Activator's WildFly inside the Docker container we were facing a `java.net.SocketException: Protocol family unavailable`. This seems to be due to IPv6 not being available inside the container, probably because it needs to be enabled (see https://docs.docker.com/config/daemon/ipv6/). What we have done is adding `-Djava.net.preferIPv4Stack=true` as an extra option for the JVM invocation in `standalone.conf` to force using IPv4.
