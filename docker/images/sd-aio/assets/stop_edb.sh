#!/bin/bash -e

echo "Stopping EDB..."
runuser -u enterprisedb -- /usr/edb/as11/bin/pg_ctl -D $PGDATA stop
