Service Activator Image
==================================

This is a standalone Service Activator image. An external database is required. When starting a container for the first time, Service Activator will be configured creating the required database structure (if it is the first node of the cluster) or adding itself to an existing SA cluster.

Usage
-----

As before mentioned, the standalone provisioning container requires an external database instance. Such database instance may be also in a container or just a regular one. If the target database is in a container you will need to make sure they are in the same network. Other than that, in order to point the container to the right database instance you need to specify some environment variables when instantiating the container, for example:

    SACONF_activator_db_vendor=Oracle
    SACONF_activator_db_hostname=172.17.0.3
    SACONF_activator_db_instance=XE
    SACONF_activator_db_user=hpsa
    SACONF_activator_db_password=secret

Note that the specified database instance and user must already exist. If you are connecting to an EnterpriseDB Postgres database then just set `SACONF_activator_db_vendor=EnterpriseDB`.

You can provide any variable supported by Service Activator Ansible roles prefixed with `SACONF_`. In order to pass environment variables to the docker container you can use either the `-e` command-line option, e.g. `-e SACONF_activator_db_hostname=172.17.0.3` or use `--env-file` along with a file containing a list of environment variables e.g. `--env-file=config.env`. You can find an example of such environment file in [`example.env`](example.env). For more information check the [official documentation on the `docker run` command](https://docs.docker.com/engine/reference/commandline/run/).

So in order to start a provisioning container on port 8080 you can run e.g.

    docker run --env-file=config.env -p 8080:8080 sa

By default, a 30-day Instant On license will be used. If you have a license file, you can supply it by bind-mounting it at `/license`, like this:

    docker run --env-file=config.env -v /path/to/license.dat:/license -p 8080:8080 sa

As usual, you can specify `-d` to start the container in detached mode. Otherwise, you should see output like this:

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

Then once configuration is finished you should see something like this:

```
PLAY RECAP *********************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0


Starting Service Activator...


Service Activator is now ready. Displaying log...

[...]

2019-10-14 09:26:28,194 INFO  [org.jboss.as] (Controller Boot Thread) WFLYSRV0025: WildFly Full 15.0.1.Final (WildFly Core 7.0.0.Final) started in 12425ms - Started 1181 of 1395 services (334 services are lazy, passive or on-demand)
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

In order to ease building a build-wrapper script (`build.sh`) is provided. This script will build the image and tag it as `sa`.

Building this image requires some assets from the Service Activator ISO and hotfix distribution directory. These assets must go into directory `dist`. You can find required files and where to locate them in the table below:

| File | Source |
| - | - |
| `HPSA-V90-1A.x86_64.rpm` | ISO (in `Binaries/Unix`) |
| `SAV90-1A-4.zip` | Hotfix distribution |
| `Ansible` (directory) | Hotfix distribution |

So the `dist` directory should look similar to this:

```
dist
├── Ansible
│   ├── group_vars
│   │   └── activatornodes
│   ├── inventories
│   │   └── activator
│   │       └── hosts
│   ├── roles
│   │   ├── activator-config
│   │   │   ├── defaults
│   │   │   │   └── main.yml

[...]

│   ├── sa_install.yml
│   ├── sa_remove.yml
│   └── sa_start.yml
├── HPSA-V90-1A.x86_64.rpm
└── SAV90-1A-4.zip
```

**Note:** the build assets you will find here are meant for building container images for Service Activator version `V90-1A-4` at the moment, meaning you should use artifacts from said version in order to properly build the image. Building an image for a different version may or may not work but is not guaranteed nor tested, so be prepared for unexpected outcomes when doing so.

The build-wrapper script will perform a basic validation on this structure to prevent image building errors derived from the lack or wrong placement of reqired files.

In order to build the image behind a corporate proxy it is necessary to define the appropriate proxy environment variables. Such variables are specified by default by the build-wrapper script. In order to use a different proxy just define them as appropriate in your environment.

You can also specify whether the resulting image should be squashed to save up disk space or not by setting the `SQUASH` environment variable to either `true` or `false`. Note however that in order to squash images you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information check the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

If you want to build the image by hand, you can use the following (remember you still need the required assets in the `dist` directory):

    docker build -t sa .

or if you are behind a proxy:

    docker build -t sa \
        --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
        --build-arg http_proxy=http://your.proxy.server:8080 \
        --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
        --build-arg https_proxy=http://your.proxy.server:8080 \
        --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
        --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
        .

Extending the Base Image
------------------------

This image may be extended in order to make changes not possible through configuration such as deploying additional solutions. You can do so by using the `FROM` instruction in your `Dockerfile` pointing to this image. In order to ease extension the image supports simple addition of two kind of scripts:

- Setup scripts: these are executed the first time the container is started only
- Startup script: these are executed at every startup

So e.g. if you want to extend the image by deploying an additional solution on top of it, you could use a `Dockerfile` like this:

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

**Note:** if you have access to a registry where the image is available you can reference the image in the registry as well.

Then you need to place your solution package (in the example this is `Odyssey.zip`) and a script named `10_deploy_solution.sh` with the following contents:

```sh
$ACTIVATOR_OPT/bin/deploymentmanager DeploySolution \
    -solutionName Odyssey \
    -createTables
```

beside the `Dockerfile`.

Scripts are executed in a lexical sort manner, so `10_foo.sh` comes after `00_bar.sh` and so on. Some scripts are built-in (see next section) and so it is recommended to leave the `0*` prefix for built-in scripts and use `1*` and upwards for custom scripts in order to avoid interference. Also note scripts are executed by sourcing them from the container startup script so no need for starting with a shebang.

Technical Details
-----------------

Apart from what is described in the `Dockerfile` this build includes some shell scripts:

- `setup/00_config_sa.sh`: this script configures Service Activator using Ansible roles during the first start of the container.
- `startup/00_load_env.sh`: this script just sources `setenv` at container startup so common environment variables are available for other scripts to rely on.
- `startup.sh`: this script is the container entry point. It will execute the configuration scripts if found (meaning that they have not been executed before) and then remove them (so they are not executed again). Then it starts Service Activator. Finally it will tail `$JBOSS_HOME/standalone/log/server.log` until the container is stopped, at this point the script should recive a `SIGTERM` which will cause it to stop all previously started services. Note that Docker has a grace period of 10 seconds when stopping containers, after which it will send a `SIGKILL`. It might be the case that 10s is not long enough for Service Activator to stop, in order to give it some more time you can use the `-t` argument when stopping the container, e.g. `docker stop -t 120` to give it 120s.

Other details worth mentioning:

- Specific playbooks for Docker are not included in product Ansibles so they are instead in here. So when building the image roles are copied from the ISO/product Ansible repository and then inventories and playbooks are copied from the `assets/ansible` directory.
- Not everything in the ISO is relevant for building the image, so some paths are omitted from the context in order to reduce build time and image weight (see `.dockerignore`). Anyway since part of the ISO contents need to be copied into the image it will be heavier than it should be.
