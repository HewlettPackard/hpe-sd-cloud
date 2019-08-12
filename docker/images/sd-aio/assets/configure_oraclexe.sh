#!/bin/bash -e

echo "Creating fulfillment database..."

cp /docker/oraclexe/profile /etc/profile.d/oracle.sh
. /etc/profile.d/oracle.sh

# Configure database and create instance
cp /docker/oraclexe/oracle-xe-18c.conf /etc/sysconfig/oracle-xe-18c.conf
/etc/init.d/oracle-xe-18c configure

echo "Binding listener to localhost..."
sed -i "s/$HOSTNAME/0.0.0.0/g" $ORACLE_HOME/network/admin/listener.ora
printf "ALTER SYSTEM SET LOCAL_LISTENER='0.0.0.0';" | runuser -u oracle -- sqlplus -s / as sysdba

echo "Creating fulfillment database user..."
printf "CREATE USER HPSA IDENTIFIED BY secret DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;\nGRANT DBA TO HPSA;" | runuser -u oracle -- sqlplus -s / as sysdba

echo "Removing unnecessary stuff..."
rm -rf $ORACLE_HOME/demo
rm -rf $ORACLE_HOME/jdbc
rm -rf $ORACLE_HOME/jlib
rm -rf $ORACLE_HOME/md 
rm -rf $ORACLE_HOME/nls/demo
rm -rf $ORACLE_HOME/odbc
rm -rf $ORACLE_HOME/rdbms/jlib
rm -rf $ORACLE_HOME/rdbms/public
rm -rf $ORACLE_HOME/rdbms/demo
rm -rf $ORACLE_HOME/bin/rman
