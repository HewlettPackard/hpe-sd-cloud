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

state=$("$JBOSS_HOME/bin/jboss-cli.sh" -c --commands="read-attribute server-state" 2>/dev/null || :)
if [[ $state != running ]]; then
    exit 1
fi

uoc_pid=$(pgrep -f UOC2_SERVER)
if [[ -z "$uoc_pid" ]]; then
    exit 1
fi

exit 0
