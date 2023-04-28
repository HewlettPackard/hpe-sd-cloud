#!/bin/bash -e

nodeStatus=$(curl -fs 127.0.0.1:9990/health|jq -r '.checks[]|select(.name=="SA Health Check").data | ."node status"')
if [[ $nodeStatus != RUNNING ]]; then
    exit 1
fi

for pidfile in \
    /opt/muse/auth-service/bin/muse-auth-service-4000.pid \
    /opt/muse/registry-discover-service/bin/muse-registry-discover-service-4001.pid \
    /opt/muse/configuration-service/bin/muse-configuration-service-4003.pid \
    /opt/muse/notification-service/bin/muse-notification-service-4002.pid \
    /opt/muse/shell/run/muse-shell.pid \
    /opt/muse/gateway/run/muse-gateway.pid \
    /opt/om/hpe-om-ui-plugin-server/bin/hpe-om-ui-plugin-server-3001.pid \
    /opt/om/om-ui/run/muse-om-ui.pid \
    /opt/sd/sd-ui/run/muse-sd-ui.pid
do
    kill -0 $(cat $pidfile)
done

curl -fs -o /dev/null http://127.0.0.1/muse-auth/login
curl -fs -o /dev/null http://127.0.0.1/muse-config/configurations

exit 0
