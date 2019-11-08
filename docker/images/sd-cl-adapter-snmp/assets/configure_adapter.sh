#!/bin/bash -e

ENV_PREFIX=SDCONF_
VARFILE=/docker/ansible/extra_vars

echo "Configuring Service Director..."
echo

echo foo: bar >> $VARFILE

while IFS='=' read -r -d '' n v; do
    if [[ $n == ${ENV_PREFIX}* ]]; then
      n=${n#$ENV_PREFIX}
      echo "$n: $v" >> $VARFILE
    fi
done < <(env -0)

echo "Running configuration playbook..."
cd /docker/ansible && ansible-playbook config.yml -c local -i localhost, -e @$VARFILE || {
    echo "Service Director configuration failed. Container will stop now."
    exit 1
}
