# HPE SD All-in-One Docker image

This is an all-in-one Docker image for HPE Service Director. It includes HPE Service Director Provisioning (HPE Service Activator plus the DDE solution), the HPE SD Closed Loop (ASR Solution, Kafka, Zookeeper, and the SNMP Adapter), and the HPE MUSE-based UI. The required database for HPE Service Activator (PostgreSQL) is included as well.

## Usage

### Starting and stopping the HPE SD All-in-One container

To start HPE Service Director with HPE Service Activator UI on port 8080, HPE MUSE on port 80, and SNMP Adapter listening on port 162, run the following command:

```
docker run -p 8080:8080 -p 80:80 -p 162:162/udp sd-aio
```

As usual, you can use the `-d` option to start the container in detached mode. Otherwise, an output is displayed that is similar to the following:

```
    HPE
   _____                 _              ____  _                __
  / ___/___  ______   __(_)_______     / __ \(_)_______  _____/ /_____  _____
  \__ \/ _ \/ ___/ | / / / ___/ _ \   / / / / / ___/ _ \/ ___/ __/ __ \/ ___/
 ___/ /  __/ /   | |/ / / /__/  __/  / /_/ / / /  /  __/ /__/ /_/ /_/ / /
/____/\___/_/    |___/_/\___/\___/  /_____/_/_/   \___/\___/\__/\____/_/

Running setup scripts...
Running '00_load_env.sh'...

Running '03_start_pgsql.sh'...
Starting PostgreSQL...
pg_ctl: no server running
waiting for server to start....2023-04-17 09:54:05.075 UTC [19] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2023-04-17 09:54:05.076 UTC [19] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2023-04-17 09:54:05.077 UTC [19] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2023-04-17 09:54:05.092 UTC [19] LOG:  redirecting log output to logging collector process
2023-04-17 09:54:05.092 UTC [19] HINT:  Future log output will appear in directory "log".
 done
server started

Running startup scripts...
Running '00_load_env.sh'...

Starting Service Director...

Starting PostgreSQL...
pg_ctl: server is running (PID: 19)
/usr/pgsql-11/bin/postgres "-D" "/pgdata"
Starting event collection framework...
Starting ZooKeeper daemon (zookeeper): 
Starting Kafka daemon (kafka): 
INFO: sourcing /opt/OV/ServiceActivator/solutions/ASR/bin/asr_env.sh
INFO: sourced= /opt/OV/ServiceActivator/solutions/ASR/bin/asr_env.sh
INFO-: JBOSS_HTTP_URL=http://localhost:8080
/opt/OV/ServiceActivator/solutions/ASR/bin/kafka_setup.sh is executable file
add /opt/OV/ServiceActivator/solutions/ASR/bin to PATH
PATH=/opt/apache-maven/bin:/opt/apache-ant/bin:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/OV/ServiceActivator/bin:/opt/uoc2/bin:/root/bin
INFO: Kafka setup
WARNING: /etc/opt/OV/ServiceActivator/config/parameters/ASR_kafka.yaml not found. All default values from /opt/OV/ServiceActivator/solutions/ASR/etc/config/parameters/ASR_kafka.yaml will be used.
INFO: ASR_ZOOKEEPER_NODES= localhost:2181
INFO: ASR_KAFKA_BROKERS= localhost:9092
INFO: ASR_KTOPIC_ADAPTER_FILTER=
INFO: ASR_KTOPIC_ADAPTER_CONFIG= ktopic-asr-adapter-config
INFO: ASR_TOPIC_EVENT= topic-asr-event
INFO: ASR_REPLICATION_FACTOR= 1
INFO: ASR_TOPIC_EVENT_RETENTION_BYTES= 10000000
INFO: ASR_TOPIC_EVENT_RETENTION_MS= 604800000
INFO: ASR_TOPIC_EVENT_PARTITIONS= 16
INFO: Using Kafka in: /opt/kafka
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 16 --topic topic-asr-event --config retention.bytes=10000000 --config retention.ms=604800000
Created topic topic-asr-event.
/opt/kafka/bin/kafka-topics.sh --describe --topic topic-asr-event --bootstrap-server localhost:9092
Topic: topic-asr-event	TopicId: xs-z98xeQIGayPLSyJP1Fg	PartitionCount: 16	ReplicationFactor: 1	Configs: retention.ms=604800000,retention.bytes=10000000
	Topic: topic-asr-event	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 1	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 2	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 3	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 4	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 5	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 6	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 7	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 8	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 9	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 10	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 11	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 12	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 13	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 14	Leader: 0	Replicas: 0	Isr: 0
	Topic: topic-asr-event	Partition: 15	Leader: 0	Replicas: 0	Isr: 0
Completed updating config for topic topic-asr-event.
INFO: If needed, create ktopic-asr-adapter-config to send adapter configuration to remote adapter.
/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 --topic ktopic-asr-adapter-config --config cleanup.policy=compact
Created topic ktopic-asr-adapter-config.
Completed updating config for topic ktopic-asr-adapter-config.
Topic: ktopic-asr-adapter-config	TopicId: SK9-frfUQUeuj69O6DWxdA	PartitionCount: 1	ReplicationFactor: 1	Configs: cleanup.policy=compact,delete.retention.ms=3600000
	Topic: ktopic-asr-adapter-config	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
INFO: Done Kafka Setup date= Mon Apr 17 09:54:41 UTC 2023
Starting MUSE...
Setup MUSE authentication service
Bye.
Setup MUSE registry and discover service
Bye.
Setup MUSE configuration service

Bye.
Setup MUSE notification service
Bye.
Starting MUSE Authentication Service on the port 4000 (with MUSE_AUTH_SERVICE_HOME=/opt/muse/auth-service)
Starting MUSE Registry/Discover Service on the port 4001 (with MUSE_REGISTRY_DISCOVER_SERVICE_HOME=/opt/muse/registry-discover-service)
Starting MUSE Configuration Service on the port 4003 (with MUSE_CONFIGURATION_SERVICE_HOME=/opt/muse/configuration-service)
Starting MUSE Notification Service on the port 4002 (with MUSE_NOTIFICATION_SERVICE_HOME=/opt/muse/notification-service)
Setup OM UI plugin server
Bye.
Setup Service Director UI for MUSE
Bye.
Setup Order Manager UI for MUSE
Bye.
Starting HPE OM UI plugin server on the port 3001 (with HPE_OM_UI_PLUGIN_SERVER_HOME=/opt/om/hpe-om-ui-plugin-server)
Starting Service Activator...
TRUNCATE TABLE
UPDATE 1
Starting SNMP adapter...
Starting sd-asr-SNMPGenericAdapter_1
/usr/bin/java
Java version: 11.0.18

Service Director is now ready. Displaying Service Activator log...
```

After HPE SD has finished booting, a live `$JBOSS_HOME/standalone/log/server.log` HPE SA log is displayed until the container is stopped.

If you stop and then start the container again, a similar output is shown but without the configuration part, because configuration only needs to be done during the first run.
There is also an option when building the image to have it prepared at build time at the cost of a little bigger image. See section *Building the HPE SD All-in-One Docker image*  for more details.

### Getting a shell into the container

If you want to get a shell into the container, run the following command while the container is running:

```
docker exec -it <container_name> /bin/bash
```

If you want to log in to the container after it has stopped, run the following command instead:

```
docker start -i <container_name> /bin/bash
```

## Building the HPE SD All-in-One Docker image

The HPE SD All-in-One image is based on `sd-base-ansible`. Therefore, you need to build the base image first.

### Using the build-wrapper script

To simplify the build process, a build-wrapper script (`build.sh`) is provided. This script builds the image and tags it as `sd-aio`.

Building this image also requires the corresponding HPE Service Director ISO to be mounted or extracted into the `iso` directory.

To build the image behind a corporate proxy, it is necessary to define the appropriate proxy environment variables. By default, these variables are specified by the build-wrapper script. To use a different proxy, define the variables as appropriate in your environment.

The image can be built in two different ways:

- Non-prepared (default): This means that the software is installed into the image, but some tasks need to be performed upon the first startup of the container. These tasks include database creation, the configuration of HPE SA and MUSE, and the deployment of the DDE solution. This approach has the following advantages:
  
  - The resulting image is lighter.
  - This structure is the same that will be used for production images, because usually, we do not know about the database at build time. In this case, however, we do.
- Prepared: This means  that the image is ready to start, database instances are already created, and everything is deployed. This approach has the advantage of a faster container instantiation, but results in a heavier image.
  
  Use the `PREPARED`environment variable set to `true` to specify that the image is to be prepared at build time. Set the `PREPARED`environment variable to `false` to specify that the image is not to be built at build time.

To save disk space, you can set the `SQUASH` environment variable to `true`. If you do not want to squash the resulting image, set `SQUASH` to `false`. (The default value is `false`.)

**NOTE:** To squash images, you need to enable experimental features in the Docker daemon by adding `"experimental": true` to the `daemon.json` file. For more information, see the [official documentation](https://docs.docker.com/engine/reference/commandline/dockerd/#description).

For example, if you want to build a squashed, prepared image, and your credentials are `foo`/`bar`, run the following:

```sh
SQUASH=true ./build.sh
```

### Building the image manually

If you want to build the image manually, you can use the following command:

```
docker build -t sd-aio .
```

If you are behind a proxy, use the following command:

```
docker build -t sd-aio \
    --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
    --build-arg http_proxy=http://your.proxy.server:8080 \
    --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
    --build-arg https_proxy=http://your.proxy.server:8080 \
    --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
    --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
    .
```

If you want a non-prepared image, set `prepared` to `false` as follows:

```
docker build -t sd-aio \
    --build-arg prepared=false \
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
FROM sd-aio

# Add the solution package

ADD Odyssey.zip /

# Import the solution
# This could also be done after creating the container from a setup script

RUN /opt/OV/ServiceActivator/bin/deploymentmanager ImportSolution \
        -file /Odyssey.zip && \
    rm /Odyssey.zip

# This causes the dbAccess.cfg file to be created, so Deployment Manager can be
# used in the setup script without the database credentials

ENV SDCONF_activator_create_db_access=yes

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

## Technical details

### Built-in shell scripts

Apart from what is described in the `Dockerfile`, this build includes the following shell scripts:

- `setup/00_load_env.sh`: This script sources `setenv` at the container setup making common environment variables available for other scripts to rely on.
- `setup/01_config_pgsql.sh`: This script configures PostgreSQL and creates the database and the database user. It may be run during the build phase (prepared build) or upon the first start of the container.
- `setup/02_config_sd.sh`: This script configures HPE Service Director components using Ansible roles. It may be run during the build phase (prepared build) or upon the first start of the container.
- `setup/03_start_pgsql.sh`: This script calls the `start_pgsql.sh` script after setup.
- `startup/00_load_env.sh`: This script sources `setenv` at container startup making common environment variables available for other setup scripts to rely on.
- `start_pgsql.sh`: This script starts PostgreSQL. It handles the host name changes that occur in prepared images. The database is configured during the build phase with a certain container ID, and the host name for the final container is different.
- `startup.sh`: This script is the container entry point. It executes the configuration scripts that have not been executed before (if found) and then removes them (so that they are not executed again). Then it starts PostgreSQL, Kafka, Zookeeper, the SNMP adapter, HPE Service Activator, and HPE MUSE. Finally, it tails `$JBOSS_HOME/standalone/log/server.log` until the container is stopped. At this point, the script needs to receive a `SIGTERM` termination signal, which makes the script stop all previously started services.

**NOTE:** Docker has a grace period of 10 seconds when stopping containers, after which, it sends a `SIGKILL` signal. It might be the case that 10 seconds is not long enough for HPE Service Activator to stop. Use the `-t` argument to add more time when stopping the container. For example, use `docker stop -t 120` to give the container 120 seconds.

### Image weight

Not everything in the ISO is relevant for building the image, so some paths are omitted from the context to reduce build time and image weight (see `.dockerignore`). However, the image weight is heavier than it would be expected, because a part of the ISO contents needs to be copied into the image. This space can be recovered by squashing the image because the installation packages are removed later.

### Build-time and run-time host name

When the image is prepared at build time, the build-time host name is different from the run-time host name. Therefore, when `ActivatorConfig` is run during the build phase, the build-time host name is inserted into the `CLUSTERNODELIST` database table. To fix this, update the table with the new container host name before starting HPE SA. As there is an foreign key from `MODULES`, it is truncated first (module entries are recreated automatically).

