Service Director with Redis scenario
=============================

Here, a basic example of a Redis docker image prepared to work with Service Director can be found. As it, it is not suitable for a production environment.

As Service Activator requires an external database as well, for the purpose of this example we are using `postgres:13-alpine` for a PostgreSQL 13 database. You can find an example using an Oracle database instead in [sd-oracle](../sd-oracle). For production environments you should either use an external, non-containerized database or create an image of your own.

Redis is an open source (BSD licensed), in-memory data structure store, used as a database, cache and message broker. It is used by Service Director UI to support _push notifications_ and _session management_ in a distributed environment (when more than a UI image is deployed).

More information regarding Redis image can be found in [Redis Docker](https://hub.docker.com/_/redis/).


Model
-----

In the example we are going to set up a basic Service Director installation two UIs and a Redis image. Two UI container are being instantiated as Redis makes sense only in an UI cluster environment.

- `db`: fulfillment database server
- `sp`: provisioning node
- `ui-1`: First UOC-based UI
- `ui-2`: Second UOC-based UI
- `redis`: Redis image
- `couchdb`: CouchDB database


Customizations
--------------

In order to configure a password to the Redis image, a [configuration file](./redis.conf) should be provided (in our example we are defining the password `secret`). In a simple docker instantiation, it can be done this way:

    docker run -v /path/to/redis.conf:/usr/local/etc/redis/redis.conf redis-sd redis-server /usr/local/etc/redis/redis.conf
    
Another important customization is to add a healthcare check, as the UI image will fall back to the old system if Redis is not available. This check can be done using the CLI app provided by Redis:

    healthcheck:
        test: ["CMD-SHELL", "if ping=\"$$(redis-cli -h localhost ping)\" && [ \"$$ping\" = 'PONG' ]; then exit 0; else exit 1; fi"]
        
When using a password the redis-cli command should be compose in this way: `redis-cli -a <password> -h localhost ping`.


Integration
-----------

Configuring Service Director to work with Redis is easy, it can be done by setting the following environment variables to the UI image:

      - SDCONF_sdui_redis=yes
      - SDCONF_sdui_redis_host=<host>
      - SDCONF_sdui_redis_port=<port> #Default: 6379      
      - SDCONF_sdui_redis_password=<password> #Defined in redis.conf

There is an extra parameter to be configured so the Service Provisioner knows where to do the callback:

      - SDCONF_sdui_async_host=<ui-host>

Example
-------

A docker-compose example can be found [here](./docker-compose.yml).

Validation
----------

Be sure whenever Redis is propoerly working or not is a bit tricky as Service Director will not fail if not Redis server is found. Instead it will fallback to an alternative method. So, in case of doubt, this method can be used to validate that Redis is working and integrated with Service Director:

1. Enter the docker redis container with `docker exec -ti sd-redis_redis_1 /bin/bash`
2. Log into redis monitor application with `redis-cli -a secret -h localhost monitor` (password may be different). redis-cli is the command line interface for Redis.
3. Log into Service Director UI (usually http://localhost:3000)
4. Create a new Tenant
5. Create a new Service, for example **DDE::SOM::Order-000.01**
6. Wait for **_Creation has been successfully executed_** message
7. Check the monitor has logged a trace similar to this one:

```
1585829389.320764 [0 172.29.0.8:59166] "publish" "socket.io#/#" "\x93\xa6GhAVHR\x83\xa4type\x02\xa4data\x92\xabuoc.message\x88\xa2id\xb2service-management\xa4type\xa4data\xa6origin\xa6plugin\xa6domain\xa5hpesd\xa7package\xa5hpesp\xb0sendToSessionIds\x91\xb47wPzmmSZrtGt8CD_AAAA\xa4data\x83\xa9operation\xa6CREATE\xabservicename\xa6sdfsdf\xa8response\x83\xa6result\xa7SUCCESS\xabservicename\xa6sdfsdf\xafserviceresponse\x91\x85\xa8tenantid\xa3xxx\xabservicename\xa6sdfsdf\xa6result\xa7SUCCESS\xa6reason\xd4\x00\x00\xa8metadata\xde\x003\xaccreationdate\xbcThu Apr 02 12:09:48 UTC 2020\xaarollback__\xc2\xb0provisionedcount\x01\xa4uuid\xd9$4778e159-c050-395d-a717-8e6963742d3c\xa8children\x90\xabcompleted__\xc3\xa8forasr__\xc2\xa9is_shadow\xc2\xa5state\xa6ACTIVE\xa8simulate\xc2\xaapoolitem__\xff\xaetransaction_id\xd9$bea7b54d-41ed-46b8-ac21-74c6b1c48fd3\xaacanceled__\xc2\xa7version\xa6000.01\xa9childtype\xa7SERVICE\xafrollbackstate__\xa6NORMAL\xaeserviceversion\xa6000.01\xb3modificationdatenbr\xcf\x00\x00\x01q:\xcc\"\xdc\xb0servicetypeinput\xb6DDE::SOM::Order-000.01\xa8dataload\xc2\xb0preserveversions\xc2\xa9tenant_id\xa3xxx\xa7onerror\xc2\xafcreationdatenbr\xcf\x00\x00\x01q:\xcc b\xaacustomtree\xc3\xafactivationcount\x01\xa6ponr__\xc2\xacdesiredstate\xa6ACTIVE\xadtransactionid\xd9$bea7b54d-41ed-46b8-ac21-74c6b1c48fd3\xa9orderitem\x90\xb2overridedefended__\xa3ALL\xacwassimulated\xc2\xa8tenantid\xa3xxx\xabservicename\xa6sdfsdf\xadroottypeinput\xb6DDE::SOM::Order-000.01\xae__NEW_VALUES__\x82\xabcompleted__\xc3\xb3modificationdatenbr\xcf\x00\x00\x01q:\xcc\"\xdc\xa8approval\xa7Pending\xaepreprovisioned\xc2\xaforderitem.count\x00\xabmessagehash\xa20L\xb0modificationdate\xbcThu Apr 02 12:09:48 UTC 2020\xafforceredesign__\xc2\xabretrystep__\xc2\xabservicetype\xafDDE::SOM::Order\xb0inventorysubtype\xacOrderService\xb2presentationname__\xa6sdfsdf\xb2servicetypeversion\xb6DDE::SOM::Order-000.01\xa9serviceid\xabxxx//sdfsdf\xa6entity\xa5order\xb5lastrtmodificationnbr\xcf\x00\x00\x01q:\xcc\"\xdc\xaecomponentorder\xcf\x00\x00\x01q:\xcc b\xa9timestamp\xcf\x00\x00\x01q:\xcc$\x06\xa3nsp\xa1/\x82\xa5rooms\x90\xa5flags\x80"
```



