#!/bin/bash -e

mkdir -p $PGDATA
chown -R enterprisedb:enterprisedb $PGDATA

pwfile=$(mktemp)
echo $PGPASSWORD > $pwfile
chmod a+r $pwfile

echo "Initializing EDB..."
runuser -u enterprisedb -- /usr/edb/as11/bin/initdb -D $PGDATA -E UTF-8 -A md5 --auth-host=md5 -U enterprisedb --pwfile $pwfile
rm $pwfile

echo "Configuring EDB..."
cat > /pgdata/pg_hba.conf <<"EOF"
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               md5
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
host    replication     all             0.0.0.0/0               md5
EOF

echo "Starting EDB..."
runuser -u enterprisedb -- /usr/edb/as11/bin/pg_ctl -D $PGDATA start

echo "Creating fulfillment database..."
runuser -u enterprisedb -- /usr/edb/as11/bin/createdb sa

echo "Creating fulfillment database user..."
runuser -u enterprisedb -- /usr/edb/as11/bin/psql -d sa <<EOF
CREATE USER sa WITH PASSWORD '$PGPASSWORD';
GRANT ALL PRIVILEGES ON DATABASE sa TO sa;
EOF
