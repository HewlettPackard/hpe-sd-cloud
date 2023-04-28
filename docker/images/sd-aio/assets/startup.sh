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

    echo "Stopping MUSE..."
    for pidfile in \
        /opt/sd/sd-ui/run/muse-sd-ui.pid \
        /opt/om/om-ui/run/muse-om-ui.pid \
        /opt/om/hpe-om-ui-plugin-server/bin/hpe-om-ui-plugin-server-3001.pid \
        /opt/muse/gateway/run/muse-gateway.pid \
        /opt/muse/shell/run/muse-shell.pid \
        /opt/muse/notification-service/bin/muse-notification-service-4002.pid \
        /opt/muse/configuration-service/bin/muse-configuration-service-4003.pid \
        /opt/muse/registry-discover-service/bin/muse-registry-discover-service-4001.pid \
        /opt/muse/auth-service/bin/muse-auth-service-4000.pid
    do
        if [[ -f $pidfile ]]
        then
            kill $(cat $pidfile)
        fi
    done

    echo "Stopping Service Activator..."
    /etc/init.d/activator stop

    echo "Stopping Kafka..."
    /etc/init.d/kafka stop

    echo "Stopping Zookeeper..."
    /etc/init.d/zookeeper stop

    echo "Stopping SNMP adapter..."
    /opt/sd-asr/adapter/bin/sd-asr-SNMPGenericAdapter_1.sh stop

    echo "Stopping PostgreSQL..."
    /docker/stop_pgsql.sh
}

function runScripts {

    kind="$1"
    scriptDir="$2"

    echo "Running $kind scripts..."
    if [ -d "$scriptDir" ] && [ -n "$(ls -A "$scriptDir")" ]
    then
        for f in $scriptDir/*
        do
            n=$(basename "$f")
            case "$f" in
                *.sh)
                    echo "Running '$n'..."
                    . "$f"
                    ;;
                *.sql)
                    echo "Ignoring '$n' (running SQL scripts is not supported)"
                    echo "WARNING: Running SQL scripts is not supported"
                    ;;
                *)
                    echo "Ignoring '$n' (unknown file extension)"
            esac
            echo
        done
    else
        echo "No $kind scripts found."
    fi
}

################################################################################
# Main
################################################################################

SCRIPTS_DIR=/docker/scripts
SETUP_DONE_MARK=/docker/.setup.done

[[ -f $SETUP_DONE_MARK ]] || runScripts setup $SCRIPTS_DIR/setup
touch $SETUP_DONE_MARK

runScripts startup $SCRIPTS_DIR/startup

echo "Starting Service Director..."
echo

/docker/start_pgsql.sh

echo "Starting event collection framework..."

/etc/init.d/zookeeper start
sleep 5
/etc/init.d/kafka start

ASR_CONFIGURED_MARK=/docker/.asr_configured

if [[ ! -f $ASR_CONFIGURED_MARK ]]
then
    sleep 5
    /opt/OV/ServiceActivator/solutions/ASR/bin/kafka_setup.sh
    touch $ASR_CONFIGURED_MARK
fi

echo "Starting MUSE..."

MUSE_CONFIGURED_MARK=/docker/.muse_configured

if [[ ! -f $MUSE_CONFIGURED_MARK ]]
then
    /opt/muse/auth-service/scripts/setup.sh -s
    /opt/muse/registry-discover-service/scripts/setup.sh -s
    /opt/muse/configuration-service/scripts/setup.sh -s
    /opt/muse/notification-service/scripts/setup.sh -s
fi

sudo -u muse /opt/muse/auth-service/bin/muse-auth-service start -p 4000
sudo -u muse /opt/muse/registry-discover-service/bin/muse-registry-discover-service start -p 4001
sudo -u muse /opt/muse/configuration-service/bin/muse-configuration-service start -p 4003
sudo -u muse /opt/muse/notification-service/bin/muse-notification-service start -p 4002
nginx -c /opt/muse/shell/etc/nginx.conf -p /opt/muse/shell/share
nginx -c /opt/muse/gateway/etc/nginx.conf -p /opt/muse/gateway/share

if [[ ! -f $MUSE_CONFIGURED_MARK ]]
then
    /opt/om/hpe-om-ui-plugin-server/scripts/setup.sh -s
    /opt/sd/sd-ui/scripts/setup.sh -s
    /opt/om/om-ui/scripts/setup.sh -s
fi

sudo -u om /opt/om/hpe-om-ui-plugin-server/bin/hpe-om-ui-plugin-server start -p 3001
nginx -c /opt/sd/sd-ui/etc/nginx.conf -p /opt/sd/sd-ui/share
nginx -c /opt/om/om-ui/etc/nginx.conf -p /opt/om/om-ui/share

touch $MUSE_CONFIGURED_MARK

echo "Starting Service Activator..."

. /opt/OV/ServiceActivator/bin/setenv

# Update CLUSTERNODELIST

node_ip=$(hostname -i)
psql -U sa <<EOF
TRUNCATE TABLE MODULES;
UPDATE CLUSTERNODELIST SET HOSTNAME='$HOSTNAME', IPADDRESS='$node_ip';
EOF

# Cleanup standalone.xml history to prevent issues with prepared containers

rm -fr "$JBOSS_HOME/standalone/configuration/standalone_xml_history"

# Cleanup log dirs from intermediate containers created during prepared build

find /var/opt/OV/ServiceActivator/log \
    -mindepth 1 -type d -not -name "$HOSTNAME" -print0 | xargs -0 rm -fr

/etc/init.d/activator start


echo "Starting SNMP adapter..."
/opt/sd-asr/adapter/bin/sd-asr-SNMPGenericAdapter_1.sh start

trap finish EXIT

echo
echo "Service Director is now ready. Displaying Service Activator log..."
echo

tail -f "$JBOSS_HOME/standalone/log/server.log"
