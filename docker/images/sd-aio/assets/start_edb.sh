#!/bin/bash -e

echo "Starting EDB..."
runuser -u enterprisedb -- /usr/edb/as11/bin/pg_ctl -D "$PGDATA" status || \
runuser -u enterprisedb -- /usr/edb/as11/bin/pg_ctl -D "$PGDATA" start