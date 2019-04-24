#!/bin/bash -e

uoc_pid=$(ps -ef | grep UOC2_SERVER | grep -v grep | awk '{print $2}')
if [[ -z "$uoc_pid" ]]; then
    exit 1
fi

exit 0
