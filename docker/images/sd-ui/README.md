# HPE SD UI Standalone Docker image

This is a standalone HPE Service Director (SD) UI image. It includes HPE UOC and the HPE Service Director UI plug-in. When starting a container for the first time, the HPE Service Director UI is configured, creating the required database structures and configuration files. The container needs to be connected to an HPE SD Provisioning instance (see section [HPE SD Provisioning image](../sd-sp/README.md) and a CouchDB instance.

## Usage

### Setting database-related variables

The required HPE SD Provisioning instance and the C[](https://)ouchDB instance can be containers (`couchdb`, `sd-sp`) or not (external). If they are containers, they need to be in the same network. To point the UI to the right HPE SD Provisioning instance, specify the related environment variables when instantiating the container, for example, as follows:

```
SDCONF_sdui_provision_host=172.17.0.1
SDCONF_sdui_provision_port=8080
SDCONF_sdui_provision_protocol=http
SDCONF_sdui_provision_tenant=UOC_SD
SDCONF_sdui_provision_username=admin
SDCONF_sdui_provision_password=admin001
SDCONF_sdui_provision_use_real_user=no
SDCONF_sdui_install_assurance=yes
SDCONF_uoc_couchdb_host=172.17.0.3
SDCONF_uoc_couchdb_admin_username=admin
SDCONF_uoc_couchdb_admin_password=admin
```

### Passing environment variables to the Docker container

You can provide any variable supported by HPE Service Director Ansible roles prefixed with `SDCONF_`. To pass environment variables to the Docker container, you can choose from two options:

- Use the `-e` command-line option, for example, as follows:

  ```
  -e SDCONF_sdui_install_assurance=yes
  ```
- Use the `--env-file` option along with a file containing a list of environment variables, for example, `--env-file=config.env`. You can find an example of such environment files in [`example.env`](example.env). For more information, check the [official documentation on the `docker run` command](https://docs.docker.com/engine/reference/commandline/run/).

### Starting and stopping the HPE SD Provisioning container

To start HPE Service Director UI on port 3000, you can run the following command:

```
docker run --env-file=config.env -p 3000:3000 sd-ui
```

As usual, you can use the `-d` option to start the container in detached mode. Otherwise, the expected output is as follows:

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
localhost                  : ok=8    changed=5    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0

Starting Service Director...

Waiting for CouchDB to be ready...
Starting UOC...
Starting UOC server on the port 3000 (with UOC2_HOME=/opt/uoc2)

Service Director UI is now ready. Showing UOC log...

Node Root is /opt/uoc2
Authentication mode is local

Startup parameters:

- loadLocalUIData       [true]
- overwriteLocalUIData  [true]
- loadRemoteUIData      [true]
- overwriteRemoteUIData [true]

Unified Console started in 24 seconds...
```

After HPE SD has finished booting, a live HPE UOC log, `$UOC_HOME/logs/uoc_startup.log`, is displayed until the container is stopped.

**NOTE:** If you stop and then start the container again, a similar output is shown but without the preparation part, because this preparation only needs to be done on the first run.

### Getting a shell into the container

If you want to get a shell into the container, run the following command while the container is running:

```
docker exec -it <container_name> /bin/bash
```

If you want to log in to the container when it is stopped, instead of the previous command, run the following:

```
docker start -i <container_name> /bin/bash
```

### Using a non-root user for the container

Containers run as root by default, but the HPE SD UI Standalone Docker image supports creating containers running as a different user. You can do so by using the `--user` option as shown in the following examples:

```
--user=sd
```

```
--user=1001:1000
```

For more information, see the official [Docker documentation](https://docs.docker.com/).

## Building the standalone HPE SD UI image

The HPE SD UI Standalone Docker image is based on the `sd-base-ansible` base image. Therefore, you need to build the base image first.

### Using the build-wrapper script

To simplify the building, a build-wrapper script (`build.sh`) is provided. This script does the following:

- Makes sure that all the required files are present and match the expected SHA-1 hashes.
- Builds the image and tags it as `sd-ui`.

Building this image also requires the corresponding HPE SD ISO to be mounted or extracted into the `iso` directory.

To build the image behind a corporate proxy, it is necessary to define the appropriate proxy environment variables. By default, these variables are specified by the build-wrapper script. To use a different proxy, define the variables as appropriate in your environment.

To save disk space, you can set the `SQUASH` environment variable to `true`. If you do not want to squash the resulting image, set `SQUASH` to `false`. (The default value is `false`.)

**NOTE:** To squash images, you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information, see the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

### Building the image manually

If you want to build the image manually, use the following command:

```
docker build -t sd-ui .
```

However, if you are behind a proxy, execute the following command:

```
docker build -t sd-ui \
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

In addition to what is described in the `Dockerfile`, this build includes the following shell scripts:

- `configure_ui.sh`: This script configures the HPE Service Director UI using Ansible roles, including HPE UOC, the HPE SD UI plug-in and CouchDB initialization.
- `startup.sh`: This script is the container entry point. It executes the configuration scripts that have not been executed before (if found) and then removes them (so they are not executed again). Then, it starts HPE UOC. Finally, it tails the `$UOC_HOME/logs/uoc_startup.log` file until the container is stopped. At this point, the script needs to receive a `SIGTERM` termination signal, which makes the script stop all the previously started services.

**NOTE:** Docker has a grace period of 10 seconds when stopping containers, after which, it sends a `SIGKILL` signal. It might be the case that 10 seconds is not long enough for HPE Service Activator to stop. Use the `-t` argument to add more time, for example, `docker stop -t 120`, to give 120 seconds before stopping the container.

### Specific playbooks for containers

Specific playbooks for containers are not included in product Ansibles, so they are added here. When building, the image roles are copied from the HPE SD ISO or the Ansible repository. Then, inventories and playbooks are copied from the `assets/ansible` directory.

### Image weight

Not everything in the HPE SD ISO is relevant for building the image, so some paths are omitted from the context to reduce build time and image weight (see `.dockerignore`). However, the image weight is heavier than it would be expected, because part of the HPE SD ISO contents needs to be copied into the image.
