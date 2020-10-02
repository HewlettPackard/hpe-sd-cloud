#!/bin/bash
echo "Grok-exporter starting"
until test 30 -eq 0 -o -f "/alarms-log/alarms_active.xml" ; do sleep 10; done
echo "Service activator ready!!"
/grok/grok_exporter -config /grok/config.yml