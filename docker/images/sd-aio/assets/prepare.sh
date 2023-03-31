#!/bin/bash -e

/docker/scripts/setup/01_config_pgsql.sh
rm /docker/scripts/setup/01_config_pgsql.sh
/docker/scripts/setup/02_config_sd.sh
rm /docker/scripts/setup/02_config_sd.sh
/docker/stop_pgsql.sh
rm -fr /var/opt/OV/ServiceActivator/log/*
rm -fr /var/opt/OV/ServiceActivator/patch/*
find /var/log /var/opt/kafka/logs -type f -delete
