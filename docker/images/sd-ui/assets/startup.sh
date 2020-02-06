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
}

function wait_couch {
    printf "Waiting for CouchDB to be ready..."
    until curl -sIfo /dev/null $(cat /docker/couchdb_url)
    do
        printf '.'
        sleep 1
    done
    echo
}

################################################################################
# Main
################################################################################

# Run pending configuration scripts
for c in ui; do
    s=/docker/configure_${c}.sh
    if [[ -f $s ]]; then
        . $s
        rm $s
    fi
done

echo "Starting Service Director..."
echo

wait_couch

echo "Starting UOC..."
su uoc -c 'touch /opt/uoc2/logs/uoc_startup.log'
su uoc -c '/opt/uoc2/bin/uoc2 start'

trap finish EXIT

echo
echo "Service Director UI is now ready. Showing UOC log..."
echo

tail -F /opt/uoc2/logs/uoc_startup.log
