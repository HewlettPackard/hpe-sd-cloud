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

SCRIPTS_DIR=/docker/scripts
SETUP_DONE_MARK=/docker/.setup.done

[[ -f $SETUP_DONE_MARK ]] || runScripts setup $SCRIPTS_DIR/setup
touch $SETUP_DONE_MARK

runScripts startup $SCRIPTS_DIR/startup

echo
echo "Starting Service Activator..."
echo

/etc/init.d/activator start

ASR_CONFIGURED_MARK=/docker/.asr_configured
VARFILE=/docker/ansible/extra_vars

if [[ -f /docker/.kafka_config && ! -f $ASR_CONFIGURED_MARK ]]
then
    (cd /docker/ansible && ansible-playbook asr_config.yml -c local -i localhost, -e @$VARFILE)
    touch $ASR_CONFIGURED_MARK
fi

trap finish EXIT

echo
echo "Service Activator is now ready. Displaying log..."
echo

mkdir -p "$JBOSS_HOME/standalone/log"
touch "$JBOSS_HOME/standalone/log/server.log"
tail -F "$JBOSS_HOME/standalone/log/server.log"
