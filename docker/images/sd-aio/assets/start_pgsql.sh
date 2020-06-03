#!/bin/bash -e

echo "Starting PostgreSQL..."
runuser -u postgres -- /usr/pgsql-11/bin/pg_ctl -D "$PGDATA" status || \
runuser -u postgres -- /usr/pgsql-11/bin/pg_ctl -D "$PGDATA" start