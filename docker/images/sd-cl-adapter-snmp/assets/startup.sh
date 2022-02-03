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

    echo "Stopping SNMP adapter..."
    /opt/sd-asr/adapter/bin/sd-asr-SNMPGenericAdapter_1.sh stop
}

################################################################################
# Main
################################################################################

. /docker/common.sh

enable_rootless

# Run pending configuration scripts
for c in adapter; do
    s=/docker/configure_${c}.sh
    if [[ -f $s ]]; then
        . $s
        rm $s
    fi
done

echo "Starting Service Director..."
echo

echo "Starting SNMP adapter..."
/opt/sd-asr/adapter/bin/sd-asr-SNMPGenericAdapter_1.sh start

trap finish EXIT

echo
echo "Service Director SNMP adapter is now ready. Showing adapter log..."
echo

tail -F /opt/sd-asr/adapter/log/SNMPGenericAdapter_1.log
