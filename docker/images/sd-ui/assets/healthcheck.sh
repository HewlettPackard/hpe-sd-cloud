#!/bin/bash -e

uoc_pid=$(pgrep -f UOC2_SERVER)
if [[ -z "$uoc_pid" ]]; then
    exit 1
fi

exit 0
