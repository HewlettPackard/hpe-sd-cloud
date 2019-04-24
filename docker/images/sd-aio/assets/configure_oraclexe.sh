#!/bin/bash -e

echo "Creating fulfillment database..."

echo . $(rpm -ql oracle-xe|grep /oracle_env.sh$) > /etc/profile.d/oracle.sh
. /etc/profile.d/oracle.sh

# Disable memory target if ShmSize is < 1g
if (( $(df /dev/shm --output=size|sed 1d) < 1048576 ))
then
    sed -i /memory_target=/d $ORACLE_HOME/config/scripts/init.ora
    sed -i /memory_target=/d $ORACLE_HOME/config/scripts/initXETemp.ora
fi

# Create a copy of original listener.ora and tnsnames.ora files
cp $ORACLE_HOME/network/admin/listener.ora{,.orig}
cp $ORACLE_HOME/network/admin/tnsnames.ora{,.orig}

# Configure database and create instance
/etc/init.d/oracle-xe configure responseFile=/docker/oraclexe/xe.rsp

echo "Creating fulfillment database user..."
printf "create user hpsa identified by secret;\\ngrant dba to hpsa;" | sqlplus -s system/secret@xe
