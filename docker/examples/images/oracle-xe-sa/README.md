Oracle XE 11g Docker Image for Service Activator
================================================

**Note:** this example is deprecated. Check [oracledb-18xe-sa](../oracledb-18xe-sa) instead.

This is a Docker image definition for creating a container with an Oracle XE 11g database prepared to install Service Activator as recommended. There is an `HPSA` user (password is `secret`) with all the privileges required for a Service Activator installation. The image also supports health check.

It is based on [wnameless/oracle-xe-11g](https://hub.docker.com/r/wnameless/oracle-xe-11g/).

In order to build you just need to run

    docker build -t NAME .

e.g.

    docker build -t oracle-xe-sa .
