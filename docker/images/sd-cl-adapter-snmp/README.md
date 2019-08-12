SD SNMP adapter Image
=============================

This is a standalone Service Director SNMP adapter image.


Usage
-----

The SNMP adapter requires a list of Kafka bootstrap nodes to connect to. This must be specified through environment variables, for example:

    SDCONF_asr_adapters_bootstrap_servers=172.17.0.1:9092,172.17.0.2:9092

You can provide any variable supported by Service Director Ansible roles prefixed with `SDCONF_`. In order to pass environment variables to the docker container you can use either the `-e` command-line option, e.g. `-e SDCONF_asr_adapters_bootstrap_servers=172.17.0.1:9092,172.17.0.2:9092` or use `--env-file` along with a file containing a list of environment variables e.g. `--env-file=config.env`. You can find an example of such environment file in [`example.env`](example.env). For more information check the [official documentation on the `docker run` command](https://docs.docker.com/engine/reference/commandline/run/).

So in order to start Service Director SNMP adapter listening for traps on port 162 (UDP) you can run

    docker run --env-file=config.env -p 162:162/udp sd-cl-adapter-snmp

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

PLAY [localhost] ***************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]
[...]
```

Then once configuration is finished you should see something like this:

```
PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=3    unreachable=0    failed=0

Starting Service Director...

Starting SNMP adapter...
Starting sd-asr-SNMPGenericAdapter_1

Service Director SNMP adapter is now ready. Showing adapter log...
```

Once the adapter has finished booting you will see a live `/opt/sd-asr/adapter/log/SNMPGenericAdapter_1.log` until the container is stopped.

If you stop and then start the container again you will see a similar output just without the preparation part as this only needs to be done on the first run.

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
- Build the image and tag it as `sd-cl-adapter-snmp`.

Building this image also requires the correspoding Service Director ISO to be mounted/extracted into the `iso` directory.

In order to build the image behind a corporate proxy it is necessary to define the appropriate proxy environment variables. Such variables are specified by default by the build-wrapper script. In order to use a different proxy just define them as appropriate in your environment.

You can also specify whether the resulting image should be squashed to save up disk space or not by setting the `SQUASH` environment variable to either `true` or `false` (default is `false`). Note however that in order to squash images you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information check the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

If you want to build the image by hand, you can use the following:

    docker build -t sd-cl-adapter-snmp .

or if you are behind a proxy:

    docker build -t sd-cl-adapter-snmp \
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

- `configure_adapter.sh`: this script configures the Service Director SNMP adapter using Ansible roles from the ISO.
- `startup.sh`: this script is the container entry point. It will execute the configuration scripts if found (meaning that they have not been executed before) and then remove them (so they are not executed again). Then it starts the adapter. Finally it will tail `/opt/sd-asr/adapter/log/SNMPGenericAdapter_1.log` until the container is stopped, at this point the script should recive a `SIGTERM` which will cause it to stop all previously started services. Note that Docker has a grace period of 10 seconds when stopping containers, after which it will send a `SIGKILL`. It might be the case that 10s is not long enough for Service Activator to stop, in order to give it some more time you can use the `-t` argument when stopping the container, e.g. `docker stop -t 120` to give it 120s.

Other details worth mentioning:

- Specific inventories and playbooks for Docker are not included in product Ansibles for now so they are instead in here. So when building the image roles are copied from the ISO/product Ansible repository and then inventories and playbooks are copied from the `assets/ansible` directory.
- Not everything in the ISO is relevant for building the image, so some paths are omitted from the context in order to reduce build time and image weight (see `.dockerignore`). Anyway since part of the ISO contents need to be copied into the image it will be heavier than it should be.
