#!/bin/bash -e

SNMP_ADAPTER_PIDFILE=/var/run/sd-asr-SNMPGenericAdapter_1.pid
[[ -f $SNMP_ADAPTER_PIDFILE ]] || exit 1
pid=$(cat $SNMP_ADAPTER_PIDFILE)
kill -0 "$pid" || exit 1
exit 0
