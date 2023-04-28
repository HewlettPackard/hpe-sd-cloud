#!/bin/bash -e

mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"

pwfile=$(mktemp)
echo "$PGPASSWORD" > "$pwfile"
chmod a+r "$pwfile"

echo "Initializing PostgreSQL..."
runuser -u postgres -- /usr/pgsql-11/bin/initdb -D "$PGDATA" -E UTF-8 -A md5 --auth-host=md5 -U postgres --pwfile "$pwfile"

rm "$pwfile"

echo "Configuring PostgreSQL..."
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

echo "listen_addresses = '0.0.0.0'" >> /pgdata/postgresql.conf

echo "Starting PostgreSQL..."
runuser -u postgres -- /usr/pgsql-11/bin/pg_ctl -D "$PGDATA" start

echo "Creating fulfillment database..."
runuser -u postgres -- /usr/pgsql-11/bin/createdb sa

echo "Creating fulfillment database user..."
runuser -u postgres -- /usr/pgsql-11/bin/psql -d sa <<EOF
CREATE USER sa WITH PASSWORD '$PGPASSWORD';
GRANT ALL PRIVILEGES ON DATABASE sa TO sa;
CREATE DATABASE muse;
CREATE USER muse WITH PASSWORD '$PGPASSWORD';
GRANT ALL PRIVILEGES ON DATABASE muse TO muse;
EOF
