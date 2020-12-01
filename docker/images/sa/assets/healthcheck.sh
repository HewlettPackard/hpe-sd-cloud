#!/bin/bash -e

nodeStatus=$(curl -fs 127.0.0.1:9990/health|jq -r '.checks[]|select(.name=="SA Health Check").data | ."node status"')
if [[ $nodeStatus != RUNNING ]]; then
    exit 1
fi

exit 0
