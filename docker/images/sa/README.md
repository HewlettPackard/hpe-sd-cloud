# HPE Service Activator image

This is a standalone HPE Service Activator image. An external database is required. When starting a container for the first time, HPE Service Activator is configured creating the required database structure (if it is the first node of the cluster) or adding itself to an existing HPE SA cluster.

## Usage

### Setting database-related variables

The external database instance required by the standalone provisioning container can be in a container or a regular database instance. If the target database is in a container, make sure that the database and the provisioning container are in the same network. Other than that, in order to point the container to the right database instance, you need to specify some environment variables when instantiating the container, for example:

```
SACONF_activator_db_vendor=Oracle
SACONF_activator_db_hostname=172.17.0.3
SACONF_activator_db_instance=XE
SACONF_activator_db_user=hpsa
SACONF_activator_db_password=secret
```

**NOTE:** The specified database instance and user must already exist. If you are connecting to an EnterpriseDB database, set `SACONF_activator_db_vendor=EnterpriseDB`. If you are connecting to a PostgreSQL database, set `SACONF_activator_db_vendor=PostgreSQL`


### Passing environment variables to the Docker container

You can provide any variable supported by HPE Service Activator Ansible roles prefixed with `SACONF_`. To pass environment variables to the Docker container, you can choose from two options:

- Use the `-e` command-line option, for example, as follows:
  
  ```
  -e SACONF_activator_db_hostname=172.17.0.3`
  ```
- Use the `--env-file` option along with a file containing a list of environment variables, for example, `--env-file=config.env`. You can find an example of such environment files in [`example.env`](example.env). For more information, check the [official documentation on the docker run command](https://docs.docker.com/engine/reference/commandline/run/).

## Starting and stopping the HPE SA Provisioning container

To start an HPE SA Provisioning container on port 8080, you can run, for example, the following command:

```
docker run --env-file=config.env -p 8080:8080 sa
```

By default, a 180-day *Instant On license* is used. If you have a license file, you can supply it by bind-mounting it at `/license` as shown in the following example. In the example, `/path/to/license.dat` is the path to the license file in the host.

```
docker run --env-file=config.env -v /path/to/license.dat:/license -p 8080:8080 sa
```

As usual, you can specify the `-d` option to start the container in detached mode. Otherwise, an output is displayed that is similar to the following:

```
    HPE
   ____             _           ___      __  _           __
  / __/__ _____  __(_)______   / _ |____/ /_(_)  _____ _/ /____  ____
 _\ \/ -_) __/ |/ / / __/ -_) / __ / __/ __/ / |/ / _ `/ __/ _ \/ __/
/___/\__/_/  |___/_/\__/\__/ /_/ |_\__/\__/_/|___/\_,_/\__/\___/_/

Running setup scripts...
Running '00_config_sa.sh'...
Configuring Service Activator...

Running configuration playbook...

PLAY [localhost] ***************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

[...]
```

After the configuration is finished, the information displayed is similar to the following:

```
PLAY RECAP *********************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0


Starting Service Activator...

Service Activator is now ready. Displaying log...

[...]

2019-10-14 09:26:28,194 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Full 15.0.1.Final (WildFly Core 7.0.0.Final) started in 12425ms - Started 1181 of 1395 services (334 services are lazy, passive or on-demand)
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

Containers run as root by default, but the HPE Service Activator image supports creating containers running as a different user. You can do so by using the `--user` option as shown in the following examples:

```
--user=sa
```

```
--user=1001:1000
```

For more information, see the official [Docker documentation](https://docs.docker.com/).

## Building the HPE Service Activator image

The HPE Service Activator image is based on `sd-base-ansible`. Therefore, you need to build the base image first.

### Using the build-wrapper script

To simplify the build process, a build-wrapper script (`build.sh`) is provided. This script builds the image and tags it as `sa`.

Building this image requires some assets from the HPE Service Activator distribution directory. These assets must go into the `dist` directory. The following table shows the required files and where to locate them:

| File             | Source                         |
| ---------------- | ------------------------------ |
| `SAV91-1A-18.zip` | Service Activator distribution |
| `Ansible.tar.gz` | Service Activator distribution |

The `dist` directory should look similar to the following structure:

```
dist
├── Ansible.tar.gz
└── SAV91-1A-18.zip
```

**NOTE:** The build assets you find here are meant for building container images for HPE Service Activator version `V91-1A-18`. This means that you have to use artifacts of that version to build the image properly. It is neither guaranteed nor tested whether building an image for a different version using these assets works or not. Be prepared for unexpected outcomes when doing so.


The build-wrapper script performs a basic validation on this structure to prevent image building errors derived from the lack or wrong placement of the required files.

To build the image behind a corporate proxy, it is necessary to define the appropriate proxy environment variables. By default, these variables are specified by the build-wrapper script. To use a different proxy, define the variables as appropriate in your environment.

To save disk space, you can set the `SQUASH` environment variable to `true`. If you do not want to squash the resulting image, set `SQUASH` to `false`. (The default value is `false`.)

**NOTE:** To squash images, you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information, see the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

### Building the image manually

If you want to build the image manually, you can use the following command:

```
docker build -t sa .
```

**NOTE:** You need the required assets in the `dist` directory.

If you are behind a proxy, use the following command:

```
docker build -t sa \
    --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
    --build-arg http_proxy=http://your.proxy.server:8080 \
    --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
    --build-arg https_proxy=http://your.proxy.server:8080 \
    --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
    --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
    .
```

## Extending the base image

This image might be extended to make changes that are not possible through configuration, such as deploying additional solutions.

You can extend the image as follows:

Use the `FROM` instruction in your `Dockerfile` pointing to the image.

To make the extension easier, the image supports the addition of two kinds of scripts:

- Setup scripts: These are executed only the first time the container is started.
- Startup script: These are executed at every startup.

For example, if you want to extend the image by deploying an additional solution on top of it, you can use a `Dockerfile` as follows:

```Dockerfile
FROM sa

# Add the solution package

ADD Odyssey.zip /

# Import the solution
# This could also be done after creating the container from a setup script

RUN /opt/OV/ServiceActivator/bin/deploymentmanager ImportSolution \
        -file /Odyssey.zip && \
    rm /Odyssey.zip

# This causes the dbAccess.cfg file to be created, so Deployment Manager can be
# used in the setup script without the database credentials

ENV SACONF_activator_create_db_access=yes

# Add a setup script responsible for deploying the solution during first startup

ADD 10_deploy_solution.sh /docker/scripts/setup/
```

**NOTE:** If you have access to a registry where the image is available, you can reference the image in the registry as well.

Then, you need to place your solution package (in the example, this is `Odyssey.zip`) and a script named `10_deploy_solution.sh` beside the `Dockerfile` with the following contents:

```sh
$ACTIVATOR_OPT/bin/deploymentmanager DeploySolution \
   -solutionName Odyssey \
   -createTables \
   -conditionalDB
```

**NOTE:** This is just an example. For more details, check our [Solution deployment recommendations for cloud environments](../../doc/SolutionDeployment.md).

Scripts are executed in a lexicographical order, for example, `10_foo.sh` comes after `00_bar.sh`. Some scripts are built-in, therefore, it is recommended to leave the `0*` prefix for built-in scripts, and use `1*` and upwards for custom scripts to avoid interference. For more details on built-in scripts, see the [Technical details](#technical-details) section.

**NOTE:** When scripts are executed, they are sourced from the container startup script; therefore, there is no need to start with a shebang.

**NOTE:** If you want to run your extended image as a non-root user, consider whether anything that will need to be read, written, or executed at runtime has the corresponding permissions set for anyone. At build time, you usually do not know what the effective runtime UID or GID will be (if you do, you can set file and directory modes and ownership more accurately).

## Technical details

### Built-in shell scripts

Apart from what is described in the `Dockerfile`, this build includes the following shell scripts:

- `setup/00_config_sa.sh`: This script configures HPE Service Activator using Ansible roles during the first start of the container.
- `startup/00_load_env.sh`: This script sources `setenv` at container startup making common environment variables available for other scripts to rely on.
- `startup.sh`: This script is the container entry point. It executes the configuration scripts that have not been executed before (if found) and then removes them (so that they are not executed again). Then it starts HPE Service Activator. Finally, it tails `$JBOSS_HOME/standalone/log/server.log` until the container is stopped. At this point, the script needs to receive a `SIGTERM` termination signal, which makes the script stop all previously started services.

**NOTE:** Docker has a grace period of 10 seconds when stopping containers, after which, it sends a `SIGKILL` signal. It might be the case that 10 seconds is not long enough for HPE Service Activator to stop. Use the `-t` argument to add more time when stopping the container, for example, `docker stop -t 120` to give it 120 seconds.

### Specific playbooks for containers

Specific playbooks for containers are not included in product Ansibles, so they are added here. When building the image, roles are copied from the distribution, and then inventories and playbooks are copied from the `assets/ansible` directory.

