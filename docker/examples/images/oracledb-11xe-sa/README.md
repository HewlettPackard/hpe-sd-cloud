Oracle XE 11g Docker Image for Service Activator
================================================

This is a Docker image definition for creating a container with an Oracle database prepared to install Service Activator as recommended. There is an `hpsa` user (password is `secret`) with all the privileges required for a Service Activator installation. The image also supports health check.

The included Dockerfile extends the `oracle/database:11.2.0.2-xe` image, which you can build following instructions from [oracle/docker-images](https://github.com/oracle/docker-images/blob/master/OracleDatabase/SingleInstance/README.md). In particular, in order to build the required image you would need to run `./buildDockerImage.sh -v 11.2.0.2 -x`.

Once you have built the `oracle/database:11.2.0.2-xe` image, you just need to run (from this directory)

    docker build -t NAME .

e.g.

    docker build -t oracledb-11xe-sa .

Then in order to start a container just run

    docker run --shm-size=1G -d -p 1521:1521 oracledb-11xe-sa
