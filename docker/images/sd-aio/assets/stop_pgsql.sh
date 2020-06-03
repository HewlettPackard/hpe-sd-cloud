#!/bin/bash -e

echo "Stopping PostgreSQL..."
runuser -u postgres -- /usr/pgsql-11/bin/pg_ctl -D "$PGDATA" stop