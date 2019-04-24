FROM wnameless/oracle-xe-11g

ENV HEALTHCHECK_SCRIPT=/docker/healthcheck.sh

ADD init.sql /docker-entrypoint-initdb.d/00_init.sql
ADD cleanup.sh /docker-entrypoint-initdb.d/01_cleanup.sh
ADD healthcheck.sh $HEALTHCHECK_SCRIPT

HEALTHCHECK --interval=30s --start-period=5m CMD $HEALTHCHECK_SCRIPT >/dev/null || exit 1
