# HPE SD SNMP Adapter image

This is a standalone HPE Service Director SNMP Adapter image.

## Usage

### Setting Kafka bootstrap nodes related variables

The SNMP adapter requires a list of Kafka bootstrap nodes to connect to. To specify this requirement, use environment variables, for example:

```
SDCONF_asr_adapters_bootstrap_servers=172.17.0.1:9092,172.17.0.2:9092
```

### Passing environment variables to the Docker container

You can provide any variable supported by Service Director Ansible roles prefixed with `SDCONF_`. To pass environment variables to the Docker container, you can choose from two options:

- Use the `-e` command-line option, for example, as follows:
  
  ```
  -e SDCONF_asr_adapters_bootstrap_servers=172.17.0.1:9092,172.17.0.2:9092
  ```
- Use the `--env-file` option along with a file containing a list of environment variables, for example, `--env-file=config.env`. You can find an example of such environment files in [`example.env`](example.env). For more information, check the [official documentation](https://docs.docker.com/engine/reference/commandline/run/) on the `docker run` command.

### Starting and stopping HPE Service Director SNMP adapter

To start HPE Service Director SNMP adapter listening for traps on port 162 (UDP), you can run the following command:

```
docker run --env-file=config.env -p 162:162/udp sd-cl-adapter-snmp
```

As usual, you can specify the `-d` option to start the container in detached mode. Otherwise, an output is displayed that is similar to the following:

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

[...]
```

After the configuration is finished, the information displayed is similar to the following:

```
PLAY RECAP *********************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0

Starting Service Director...

Starting SNMP adapter...
Starting sd-asr-SNMPGenericAdapter_1

Service Director SNMP adapter is now ready. Showing adapter log...

[...]

2019-10-07 08:58:21,490 INFO  [o.a.k.c.c.i.AbstractCoordinator] (pool-2-thread-1) [Consumer clientId=consumer-1, groupId=SNMPGenericAdapter_1-d80015f020ef] Discovered group coordinator 1cb6a95cad20:9092 (id: 2147482646 rack: null)
```

After HPE Service Activator finished booting, a live `/opt/sd-asr/adapter/log/SNMPGenericAdapter_1.log` is displayed until the container is stopped.

If you stop and then start the container again, a similar output is shown but without the configuration part, because configuration only needs to be done during the first run.

### Getting a shell into the container

If you want to get a shell into the container, run the following command while the container is running:

```
docker exec -it <container_name> /bin/bash
```

If you want to log in to the container after it has stopped, run the following command instead:

```
docker start -i <container_name> /bin/bash
```

### Using a non-root user for the container

Containers run as root by default, but the HPE SD SNMP Adapter image supports creating containers running as a different user. You can do so by using the `--user` option as shown in the following examples:

```
--user=sd
```

```
--user=1001:1000
```

For more information, see the official [Docker documentation](https://docs.docker.com/).

## Building the HPE SD SNMP Adapter image

The HPE SD SNMP Adapter image is based on `sd-base-ansible`. Therefore, you need to build the base image first.

### Using the build-wrapper script

To simplify the build process, a build-wrapper script (`build.sh`) is provided. This script does the following:

- Ensures that all the required files are present and match the expected SHA-1 hashes.
- Builds the image and tags it as `sd-cl-adapter-snmp`.

Building this image also requires the corresponding HPE Service Director ISO to be mounted or extracted into the `iso` directory.

To build the image behind a corporate proxy, it is necessary to define the appropriate proxy environment variables. By default, these variables are specified by default by the build-wrapper script. To use a different proxy, define the variables as appropriate in your environment.

To save disk space, you can set the `SQUASH` environment variable to `true`. If you do not want to squash the resulting image, set `SQUASH` to `false`. (The default value is `false`.)

**NOTE:** To squash images, you need to enable the experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information, check the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

### Building the image manually

If you want to build the image manually, you can use the following command:

```
docker build -t sd-cl-adapter-snmp .
```

If you are behind a proxy, use the following command:

```
docker build -t sd-cl-adapter-snmp \
    --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
    --build-arg http_proxy=http://your.proxy.server:8080 \
    --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
    --build-arg https_proxy=http://your.proxy.server:8080 \
    --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
    --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
    .
```

## Technical details

### Built-in shell scripts

Apart from what is described in the `Dockerfile`, this build includes the following shell scripts:

- `configure_adapter.sh`: This script configures the HPE Service Director SNMP Adapter using Ansible roles from the HPE SD ISO.
- `startup.sh`: This script is the container entry point. It executes the configuration scripts that have not been executed before (if found) and then removes them (so that they are not executed again). Then it starts HPE SNMP adapter. Finally, it tails `/opt/sd-asr/adapter/log/SNMPGenericAdapter_1.log` until the container is stopped. At this point, the script needs to receive a `SIGTERM` termination signal, which makes the script stop all previously started services.

**NOTE:** Docker has a grace period of 10 seconds when stopping containers, after which, it sends a `SIGKILL` signal. It might be the case that 10 seconds is not long enough for HPE Service Activator to stop. Use the `-t` argument to add more time when stopping the container, for example, `docker stop -t 120` to give it 120 seconds.

### Specific playbooks for containers

Specific playbooks for containers are not included in product Ansibles, so they are added here. When building the image, roles are copied from the ISO or the Ansible repository, and then inventories and playbooks are copied from the `assets/ansible` directory.

### Image weight

Not everything in the ISO is relevant for building the image, so some paths are omitted from the context in order to reduce build time and image weight (see `.dockerignore`). However, the image weight is heavier than it would be expected, because a part of the ISO contents needs to be copied into the image.

### Using a non-privileged port

When running the adapter as a non-root user, the adapter is not able to listen on the default port 162. Instead, you need to set the `SDCONF_asr_adapters_manager_port` parameter to a non-privileged port (for example, `10162`). Then, if necessary, you can redirect that port to the public port 162 (`-p 162:10162/udp`).

