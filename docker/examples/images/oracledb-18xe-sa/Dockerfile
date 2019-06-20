FROM oracle/database:18.4.0-xe

ENV SETUP_DONE_FILE=/.setup-done

ADD 01_create_user.sql /opt/oracle/scripts/setup/
ADD 99_create_setup_done_mark.sh /opt/oracle/scripts/setup/

HEALTHCHECK --interval=1m --start-period=20m \
   CMD test -f "$SETUP_DONE_FILE" && "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1
