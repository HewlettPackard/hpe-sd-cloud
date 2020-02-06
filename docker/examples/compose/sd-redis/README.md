Service Director with Redis scenario
=============================

Here, a basic example of a Redis docker image prepared to work with Service Director can be found. As it, it is not suitable for a production environment.

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

A docker-compose example can be found [here](./docker-compose.yaml).

