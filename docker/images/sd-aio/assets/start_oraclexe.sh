#!/bin/bash -e

echo "Starting Oracle XE..."
. /etc/profile.d/oracle.sh
sed -e s/%hostname%/$HOSTNAME/g -e s/%port%/1521/g $ORACLE_HOME/network/admin/listener.ora.orig > $ORACLE_HOME/network/admin/listener.ora
sed -e s/%hostname%/$HOSTNAME/g -e s/%port%/1521/g $ORACLE_HOME/network/admin/tnsnames.ora.orig > $ORACLE_HOME/network/admin/tnsnames.ora
/etc/init.d/oracle-xe start
