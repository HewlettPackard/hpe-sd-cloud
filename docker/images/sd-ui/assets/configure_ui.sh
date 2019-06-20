#!/bin/bash -e

ENV_PREFIX=SDCONF_
VARFILE=/docker/ansible/extra_vars

echo "Configuring Service Director..."
echo

echo > $VARFILE

while IFS='=' read -r -d '' n v; do
    if [[ $n == ${ENV_PREFIX}* ]]; then
      n=${n#$ENV_PREFIX}
      echo "$n: $v" >> $VARFILE
    fi
done < <(env -0)

echo "Starting CouchDB..."
echo admin = admin >> /opt/couchdb/etc/local.ini
/etc/init.d/couchdb start

echo "Running configuration playbook..."
cd /docker/ansible && ansible-playbook ui_configure.yml -i inventory -e @$VARFILE || {
    echo "Service Director configuration failed. Container will stop now."
    exit 1
}
