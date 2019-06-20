#!/bin/bash -e

cat <<EOF
    HPE
   _____                 _              ____  _                __
  / ___/___  ______   __(_)_______     / __ \(_)_______  _____/ /_____  _____
  \__ \/ _ \/ ___/ | / / / ___/ _ \   / / / / / ___/ _ \/ ___/ __/ __ \/ ___/
 ___/ /  __/ /   | |/ / / /__/  __/  / /_/ / / /  /  __/ /__/ /_/ /_/ / /
/____/\___/_/    |___/_/\___/\___/  /_____/_/_/   \___/\___/\__/\____/_/

EOF

################################################################################
# Functions
################################################################################

function finish {
    echo "Container was asked to stop"

    echo "Stopping UOC..."
    su uoc -c '/opt/uoc2/bin/uoc2 stop'

    echo "Stopping CouchDB..."
    /etc/init.d/couchdb stop

    echo "Stopping Service Activator..."
    /etc/init.d/activator stop

    echo "Stopping Oracle XE..."
    /docker/stop_oraclexe.sh
}

function wait_couch {
    printf "Waiting for CouchDB to be ready..."
    until $(curl -sIfo /dev/null 127.0.0.1:5984); do
        printf '.'
        sleep 1
    done
    echo
}

################################################################################
# Main
################################################################################

# Run pending configuration scripts
for c in oraclexe sd; do
    s=/docker/configure_${c}.sh
    if [[ -f $s ]]; then
        . $s
        rm $s
    fi
done

# Generate Instant On license if missing

. /etc/profile.d/activator.sh
$ACTIVATOR_OPT/bin/updateLicense 1
$ACTIVATOR_OPT/bin/updateLicense 1 -dde

echo "Starting Service Director..."
echo

/docker/start_oraclexe.sh

echo "Starting CouchDB..."

/etc/init.d/couchdb start

echo "Starting Service Activator..."

. /etc/profile.d/activator.sh
. /etc/profile.d/oracle.sh

# Update CLUSTERNODELIST

node_ip=$(hostname -i)
sqlplus -s "HPSA/secret" <<EOF
truncate table modules;
update clusternodelist set hostname='$HOSTNAME', ipaddress='$node_ip';
EOF

# Cleanup standalone.xml history to prevent issues with prepared containers

rm -fr /opt/HP/jboss/standalone/configuration/standalone_xml_history

/etc/init.d/activator start

wait_couch

echo "Starting UOC..."
su uoc -c 'touch /opt/uoc2/logs/uoc_startup.log'
su uoc -c '/opt/uoc2/bin/uoc2 start'

trap finish EXIT

echo
echo "Service Director is now ready. Displaying Service Activator log..."
echo

tail -f $JBOSS_HOME/standalone/log/server.log
