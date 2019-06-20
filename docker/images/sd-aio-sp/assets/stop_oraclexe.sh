#!/bin/bash -e

echo "Stopping Oracle XE..."
. /etc/profile.d/oracle.sh
/etc/init.d/oracle-xe-18c stop
