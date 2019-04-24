#!/bin/sh

status=`su -c "$ORACLE_HOME/bin/sqlplus -S / as sysdba" oracle 2>&1 <<EOF
  set heading off
  set pagesize 0
  select status from v\\$instance;
  exit;
EOF`

cmdret=$?
if [[ $cmdret != 0 || $status != "OPEN" ]]
then
  exit 1
else
  exit 0
fi
