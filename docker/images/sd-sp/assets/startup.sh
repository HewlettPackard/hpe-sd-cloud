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

################################################################################
# Main
################################################################################

# Run pending configuration scripts
for c in sp; do
    s=/docker/configure_${c}.sh
    if [[ -f $s ]]; then
        . $s
        rm $s
    fi
done

echo "Starting Service Activator..."
echo

/etc/init.d/activator start

trap finish EXIT

echo
echo "Service Activator is now ready. Displaying log..."
echo

mkdir -p $JBOSS_HOME/standalone/log
touch $JBOSS_HOME/standalone/log/server.log
tail -F $JBOSS_HOME/standalone/log/server.log
