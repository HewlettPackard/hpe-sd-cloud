#!/bin/bash -e

echo "Starting Oracle XE..."
. /etc/profile.d/oracle.sh
/etc/init.d/oracle-xe-18c start
