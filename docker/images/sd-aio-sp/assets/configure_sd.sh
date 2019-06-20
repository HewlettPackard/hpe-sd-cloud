#!/bin/bash -e

echo "Configuring Service Director..."
echo

/docker/start_oraclexe.sh

echo "Starting CouchDB..."
echo admin = admin >> /opt/couchdb/etc/local.ini
/etc/init.d/couchdb start

echo "Running Service Director configuration playbooks..."
cd /docker/ansible && ansible-playbook sp_configure.yml -c local -i inventories/provisioning
cd /docker/ansible && ansible-playbook ui_configure.yml -c local -i inventories/uoc

echo . /opt/OV/ServiceActivator/bin/setenv > /etc/profile.d/activator.sh
. /etc/profile.d/activator.sh

# Disable IPv6, otherwise WidlFly does not start

echo JAVA_OPTS='"$JAVA_OPTS -Djava.net.preferIPv4Stack=true"' >> $JBOSS_HOME/bin/standalone.conf
