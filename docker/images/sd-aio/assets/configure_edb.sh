#!/bin/bash -e

mkdir -p $PGDATA
chown -R enterprisedb:enterprisedb $PGDATA

pwfile=$(mktemp)
echo $PGPASSWORD > $pwfile
chmod a+r $pwfile

echo "Initializing EDB..."
runuser -u enterprisedb -- /usr/edb/as11/bin/initdb -D $PGDATA -E UTF-8 -A md5 --auth-host=md5 -U enterprisedb --pwfile $pwfile
rm $pwfile

echo "Starting EDB..."
runuser -u enterprisedb -- /usr/edb/as11/bin/pg_ctl -D $PGDATA start

echo "Creating fulfillment database..."
runuser -u enterprisedb -- /usr/edb/as11/bin/createdb sa

echo "Creating fulfillment database user..."
runuser -u enterprisedb -- /usr/edb/as11/bin/psql -d sa <<EOF
CREATE USER sa WITH PASSWORD '$PGPASSWORD';
GRANT ALL PRIVILEGES ON DATABASE sa TO sa;
EOF
