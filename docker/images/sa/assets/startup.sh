#!/bin/bash -e

cat <<"EOF"
    HPE
   ____             _           ___      __  _           __
  / __/__ _____  __(_)______   / _ |____/ /_(_)  _____ _/ /____  ____
 _\ \/ -_) __/ |/ / / __/ -_) / __ / __/ __/ / |/ / _ `/ __/ _ \/ __/
/___/\__/_/  |___/_/\__/\__/ /_/ |_\__/\__/_/|___/\_,_/\__/\___/_/

EOF

################################################################################
# Functions
################################################################################

function finish {
    echo "Container was asked to stop"

    echo "Stopping Service Activator..."
    /etc/init.d/activator stop
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

. /docker/rootless.sh

SCRIPTS_DIR=/docker/scripts
SETUP_DONE_MARK=/docker/.setup.done

[[ -f $SETUP_DONE_MARK ]] || runScripts setup $SCRIPTS_DIR/setup
touch $SETUP_DONE_MARK

runScripts startup $SCRIPTS_DIR/startup

echo
echo "Starting Service Activator..."
echo

mkdir -p "$JBOSS_HOME/standalone/log"

trap finish EXIT

/etc/init.d/activator start

echo
echo "Service Activator is now running. Displaying log..."
echo

touch "$JBOSS_HOME/standalone/log/server.log"
. /docker/logtail.sh
