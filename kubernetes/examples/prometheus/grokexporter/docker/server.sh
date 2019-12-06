#!/bin/bash
while [ ! -f /alarms-log/alarms_active.xml ]; do sleep 5; done;
/grok/grok_exporter -config /grok/config.yml