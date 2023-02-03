# HPE SD Provisioning image

This is a standalone HPE SD Provisioning image. It includes HPE Service Activator, DDE, and additional solutions. An external database is required. When starting a container for the first time, HPE Service Activator is configured creating the required database structure (if it is the first node of the cluster) or adding itself to an existing HPE SA cluster.

## Usage

### Setting database-related variables

The external database instance required by the standalone HPE SD Provisioning container can be in a container or a regular database instance. If the target database is in a container, make sure that the database and the HPE SD Provisioning container are in the same network. Other than that, in order to point the container to the right database instance, you need to specify some environment variables when instantiating the container, for example:

```
SDCONF_activator_db_vendor=Oracle
SDCONF_activator_db_hostname=172.17.0.3
SDCONF_activator_db_instance=XE
SDCONF_activator_db_user=hpsa
SDCONF_activator_db_password=secret
```

**NOTE:** The specified database instance and user must already exist. If you are connecting to an EnterpriseDB database, set `SDCONF_activator_db_vendor=EnterpriseDB`. If you are connecting to a PostgreSQL database, set `SDCONF_activator_db_vendor=PostgreSQL`


### Configuring HPE SD Closed Loop

You can configure if HPE SD Closed Loop should run in the cluster nodes as follows:

- If you want to run HPE SD Closed Loop in the cluster, perform the following steps:
  
  1. Specify the following environment variable for all cluster nodes:
     
     ```
     SDCONF_install_asr=yes
     ```
  2. Specify the following variable on those nodes on which you want to run HPE SD Closed Loop:
     
     ```
     SDCONF_asr_kafka_brokers=kafka1:9092,kafka2:9092,kafka3:9092 
     SDCONF_asr_zookeeper_nodes=zookeeper1:2181,zookeeper2:2181,zookeeper3:2181
     ```
  
  If you do not need the event collection chain (Kafka and Zookeeper), define this as follows:
  
  ```
  SDCONF_install_asr_kafka=no
  ```
- If you want a node in the cluster not to run HPE SD Closed Loop on (you still need to specify `SDCONF_install_asr=yes` for all of them), specify the variable as follows:
  
  ```
  SDCONF_asr_node=no
  ```
  
  By default, if HPE SD Closed Loop is deployed, nodes run it; therefore, there is no need to specify `SDCONF_asr_node=yes`.
- If you want the node to act as a pure HPE SD Closed Loop node, without running workflows, you can define this as follows:
  
  ```
  SDCONF_asr_only_node=yes
  ```

### Passing environment variables to the Docker container

You can provide any variable supported by HPE Service Director Ansible roles prefixed with `SDCONF_`. To pass environment variables to the Docker container, you can choose from two options:

- Use the `-e` command-line option, for example, as follows:
  
  ```
  -e SDCONF_activator_db_hostname=172.17.0.3
  ```
- Use the `--env-file` option along with a file containing a list of environment variables, for example, `--env-file=config.env`. You can find an example of such environment files in [`example.env`](example.env). For more information, check the [official documentation on the docker run command](https://docs.docker.com/engine/reference/commandline/run/).

### Starting and stopping the HPE SD Provisioning container

To start an HPE SD Provisioning container on port 8080, you can run, for example, the following command:

```
docker run --env-file=config.env -p 8080:8080 sd-sp
```

By default, a 30-day *Instant On license* is used. If you have a license file, you can supply it by bind-mounting it at `/license` as follows:

```
docker run --env-file=config.env -v /path/to/license.dat:/license -p 8080:8080 sd-sp
```

As usual, you can specify the `-d` option to start the container in detached mode. Otherwise, an output is displayed that is similar to the following:

```
HPE
   _____                 _              ____  _                __
  / ___/___  ______   __(_)_______     / __ \(_)_______  _____/ /_____  _____
  \__ \/ _ \/ ___/ | / / / ___/ _ \   / / / / / ___/ _ \/ ___/ __/ __ \/ ___/
 ___/ /  __/ /   | |/ / / /__/  __/  / /_/ / / /  /  __/ /__/ /_/ /_/ / /
/____/\___/_/    |___/_/\___/\___/  /_____/_/_/   \___/\___/\__/\____/_/

Running setup scripts...
Running '00_config_sp.sh'...
Configuring Service Director...

Running configuration playbook...

PLAY [localhost] ***************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

[...]
```

After the configuration is finished, the information displayed is similar to the following:

```
PLAY RECAP *********************************************************************
localhost                  : ok=20   changed=12   unreachable=0    failed=0    skipped=7    rescued=0    ignored=0


Starting Service Activator...


Service Activator is now ready. Displaying log...

[...]

2019-10-07 09:03:10,131 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Full 15.0.1.Final (WildFly Core 7.0.0.Final) started in 18167ms - Started 2235 of 2449 services (338 services are lazy, passive or on-demand)
```

After HPE Service Activator finished booting, a live `$JBOSS_HOME/standalone/log/server.log` is displayed until the container is stopped.

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

Containers run as root by default, but the HPE SD Provisioning image supports creating containers running as a different user. You can do so by using the `--user` option as shown in the following examples:

```
--user=sd
```

```
--user=1001:1000
```

For more information, see the official [Docker documentation](https://docs.docker.com/).

## Building the HPE SD Provisioning image

The HPE SD Provisioning image is based on `sd-base-ansible`. Therefore, you need to build the base image first.

### Using the build-wrapper script

To simplify the build process, a build-wrapper script (`build.sh`) is provided. This script does the following:

- Ensures that all required files are present and match the expected SHA-1 hashes.
- Builds the image and tags it as `sd-sp`.

Building this image also requires the corresponding HPE SD ISO to be mounted or extracted into the `iso` directory.

To build the image behind a corporate proxy, it is necessary to define the appropriate proxy environment variables. By default, these variables are specified by the build-wrapper script. To use a different proxy, define the variables as appropriate in your environment.

To save disk space, you can set the `SQUASH` environment variable to `true`. If you do not want to squash the resulting image, set `SQUASH` to `false`. (The default value is `false`.)

**NOTE:** To squash images, you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information, see the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

### Building the image manually

If you want to build the image manually, you can use the following command:

```
docker build -t sd-sp .
```

If you are behind a proxy, use the following command:

```
docker build -t sd-sp \
    --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
    --build-arg http_proxy=http://your.proxy.server:8080 \
    --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
    --build-arg https_proxy=http://your.proxy.server:8080 \
    --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
    --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
    .
```

## Extending the base image

For details on extending the base `sd-sp` image, see section _Extending the sd-sp image_ in chapter _Container-based Installation_ in the _Installation & Configuration Guide_ of the latest _HPE Service Director_ product documentation, which is included in the _HPE SD_ ISO file. 

## Technical details

### Built-in shell scripts

Apart from what is described in the `Dockerfile`, this build includes the following shell scripts:

- `setup/00_config_sp.sh`: This script configures HPE SD Provisioning using Ansible roles during the first start of the container. This setup configuration includes configuring HPE Service Activator and deploying DDE and additional solutions based on the configuration.
- `startup/00_load_env.sh`: This script sources `setenv` at container startup making common environment variables available for other scripts to rely on.
- `startup.sh`: This script is the container entry point. It executes the configuration scripts that have not been executed before (if found) and then removes them (so that they are not executed again). Then it starts HPE Service Activator. Finally, it tails `$JBOSS_HOME/standalone/log/server.log` until the container is stopped. At this point, the script needs to receive a `SIGTERM` termination signal, which makes the script stop all previously started services.

**NOTE:** Docker has a grace period of 10 seconds when stopping containers, after which, it sends a `SIGKILL` signal. It might be the case that 10 seconds is not long enough for HPE Service Activator to stop. Use the `-t` argument to add more time when stopping the container, for example, `docker stop -t 120` to give it 120 seconds.

### Specific playbooks for containers

Specific playbooks for containers are not included in product Ansibles, so they are added here. When building the image, roles are copied from the ISO or the Ansible repository, and then inventories and playbooks are copied from the `assets/ansible` directory.

### Image weight

Not everything in the ISO is relevant for building the image, so some paths are omitted from the context to reduce build time and image weight (see `.dockerignore`). However, the image weight is heavier than it would be expected, because a part of the ISO contents needs to be copied into the image.

