#!/bin/bash -e

protocol=$(jq -r .server.protocol < /var/opt/uoc2/server/public/conf/config.json)
port=$(jq -r .server.port < /var/opt/uoc2/server/public/conf/config.json)
curl -fsk ${protocol}://127.0.0.1:${port}/V1.0/monitoring/server/check
