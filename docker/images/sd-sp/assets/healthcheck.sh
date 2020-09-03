#!/bin/bash -e

if [[ ! -v JBOSS_HOME ]]; then
    if [ -f /opt/OV/ServiceActivator/bin/setenv ]
    then
        . /opt/OV/ServiceActivator/bin/setenv
    else
        exit 1
    fi
fi

wf_pid=$(pgrep -f _HPSA_MAIN_PROCESS_)
if [[ -z "$wf_pid" ]]; then
    exit 1
fi

state=$(
    curl \
    -m 10 \
    -s \
    --digest \
    -u $(cat /docker/.wfmgmt) \
    -X POST \
    -H 'Content-Type: application/json' \
    --data '{ "name": "server-state", "operation": "read-attribute" }' \
    http://localhost:9990/management | \
    jq -r .result
)

if [[ $state != running ]]; then
    exit 1
fi

exit 0
