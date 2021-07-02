#!/bin/bash -e

nodeStatus=$(curl -fs 127.0.0.1:9990/health|jq -r '.checks[]|select(.name=="SA Health Check").data | ."node status"')
if [[ $nodeStatus != RUNNING ]]; then
    exit 1
fi

curl -fs 127.0.0.1:3000/V1.0/monitoring/server/check

exit 0
