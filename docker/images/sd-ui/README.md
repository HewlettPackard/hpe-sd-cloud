SD UI Standalone Docker Image
=============================

This is a standalone Service Director UI image. It includes UOC plus the Service Director UI plug-in. The required CouchDB database is embedded. When starting a container for the first time, Service Director UI will be configured creating the required database structures and configuration files. As such, an external provisioning (see `sd-sp` image) instance is required to connect to.


Usage
-----

As before mentioned, the standalone Service Director UI container requires an external provisioning instance to connect to. Such instance may be also in a container (`sd-sp`) or just a regular one. If the target provisioning instance is in a container you will need to make sure they are in the same network. Other than that, in order to point the UI to the right provisioning instance you need to specify some environment variables when instantiating the container, for example:

    SDCONF_hpesd_ui_provision_host=172.17.0.1
    SDCONF_hpesd_ui_provision_port=8081
    SDCONF_hpesd_ui_provision_protocol=http
    SDCONF_hpesd_ui_provision_tenant=UOC_SD
    SDCONF_hpesd_ui_provision_username=admin
    SDCONF_hpesd_ui_provision_password=admin001
    SDCONF_hpesd_ui_provision_use_real_user=no

You can provide any variable supported by Service Director Ansible roles prefixed with `SDCONF_`. In order to pass environment variables to the docker container you can use either the `-e` command-line option, e.g. `-e SDCONF_uoc_provision_host=172.17.0.1` or use `--env-file` along with a file containing a list of environment variables e.g. `--env-file=config.env`. You can find an example of such environment file in [`example.env`](example.env). For more information check the [official documentation on the `docker run` command](https://docs.docker.com/engine/reference/commandline/run/).

So in order to start Service Director UI on port 3000 you can run

    docker run --env-file=config.env -p 3000:3000 sd-ui

As usual, you can specify `-d` to start the container in detached mode. Otherwise, you should see output like this:

```
    HPE
   _____                 _              ____  _                __
  / ___/___  ______   __(_)_______     / __ \(_)_______  _____/ /_____  _____
  \__ \/ _ \/ ___/ | / / / ___/ _ \   / / / / / ___/ _ \/ ___/ __/ __ \/ ___/
 ___/ /  __/ /   | |/ / / /__/  __/  / /_/ / / /  /  __/ /__/ /_/ /_/ / /
/____/\___/_/    |___/_/\___/\___/  /_____/_/_/   \___/\___/\__/\____/_/

Configuring Service Director...

Starting CouchDB...
Starting database server couchdb
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
Parsed /docker/ansible/inventories/uoc/hosts inventory source with ini plugin
Loading callback plugin default of type stdout, v2.0 from /usr/lib/python2.7/site-packages/ansible/plugins/callback/default.pyc

PLAYBOOK: ui_configure.yml *****************************************************
1 plays in ui_configure.yml

PLAY [uocserver] ***************************************************************

TASK [Gathering Facts] *********************************************************

[...]
```

Then once configuration is finished you should see something like this:

```
PLAY RECAP *********************************************************************
localhost                  : ok=11   changed=7    unreachable=0    failed=0

Starting Service Director...

Starting CouchDB...
Starting database server couchdb
Waiting for CouchDB to be ready...
Starting UOC...
Starting UOC server on the port 3000 (with UOC2_HOME=/opt/uoc2)

Service Director UI is now ready. Showing UOC log...

Node Root is /opt/uoc2
Authentication mode is local

Startup parameters:
- loadLocalUIData       [true]
- overwriteLocalUIData  [false]
- loadRemoteUIData      [true]
- overwriteRemoteUIData [false]

Unified Console started in 22 seconds...
```

Once SD has finished booting you will see a live UOC `$UOC_HOME/logs/uoc_startup.log` until the container is stopped.

If you stop and then start the container again you will see a similar output just without the preparation part as this only needs to be done on the first run.

If you want to get a shell into the container, you can run

    docker exec -it <container_name> /bin/bash

while it is running. If you want to log into the container while it is stopped, you can run

    docker start -i <container_name> /bin/bash

instead. You can also try [Portainer](https://portainer.io), a management UI for Docker which among other things allows you to open a console session into any running container.

Building
--------

This image is based on `sd-base-ansible` so you will need to build that one first.

Building this image requires some third party RPM packages which are not included in this repository. Such files are listed in `distfiles` along with their SHA-1 sum and a URL from where they can be downloaded when available so the build script can verify them and in some cases download them automatically. You can find a table listing such files below:

| Path | Obtain from |
| - | - |
| `kits/couchdb-1.6.1-2.el7.centos.x86_64.rpm` | Contact your HPE representative |
| `kits/js-1.8.5-19.el7.x86_64.rpm` | Contact your HPE representative |

In order to ease building a build-wrapper script `build.sh` script is provided. This script will:

- Ensure that all required files are present and match expected SHA-1 hashes
- Fetch missing files from several sources:
    - For `http[s]://` prefixed URLs, curl will be used to fetch from the Internet/intranet
- Build the image and tag it as `sd-ui`.

Building this image also requires the correspoding Service Director ISO to be mounted/extracted into the `iso` directory.

In order to build the image behind a corporate proxy it is necessary to define the appropriate proxy environment variables. Such variables are specified by default by the build-wrapper script. In order to use a different proxy just define them as appropriate in your environment.

You can also specify whether the resulting image should be squashed to save up disk space or not by setting the `SQUASH` environment variable to either `true` or `false` (default is `false`). Note however that in order to squash images you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information check the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

If you want to build the image by hand, you can use the following:

    docker build -t sd-ui .

or if you are behind a proxy:

    docker build -t sd-ui \
        --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
        --build-arg http_proxy=http://your.proxy.server:8080 \
        --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
        --build-arg https_proxy=http://your.proxy.server:8080 \
        --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
        --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
        .

Anyway if you build by hand remember that you need to make sure that you have all the files listed in `distfiles` in place, otherwise the build will fail.

Technical Details
-----------------

Apart from what is described in the `Dockerfile` this build includes a couple shell scripts:

- `configure_ui.sh`: this script configures Service Director UI using Ansible roles, including UOC, the SD UI plug-in and CouchDB initialization.
- `startup.sh`: this script is the container entry point. It will execute the configuration scripts if found (meaning that they have not been executed before) and then remove them (so they are not executed again). Then it starts CouchDB and UOC. Finally it will tail `$UOC_HOME/logs/uoc_startup.log` until the container is stopped, at this point the script should recive a `SIGTERM` which will cause it to stop all previously started services. Note that Docker has a grace period of 10 seconds when stopping containers, after which it will send a `SIGKILL`. It might be the case that 10s is not long enough for Service Activator to stop, in order to give it some more time you can use the `-t` argument when stopping the container, e.g. `docker stop -t 120` to give it 120s.

Other details worth mentioning:

- Specific inventories and playbooks for Docker are not included in product Ansibles for now so they are instead in here. So when building the image roles are copied from the ISO/product Ansible repository and then inventories and playbooks are copied from the `assets/ansible` directory.
- Not everything in the ISO is relevant for building the image, so some paths are omitted from the context in order to reduce build time and image weight (see `.dockerignore`). Anyway since part of the ISO contents need to be copied into the image it will be heavier than it should be.
