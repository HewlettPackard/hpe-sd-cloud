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

if [[ $(id -u) != 0 ]]
then
  echo uoc_rootless_container: yes >> $VARFILE
fi

# Experimental RFC5424 mode

case $EXPERIMENTAL_RFC5424_MODE in
  yes|YES|true|TRUE|True|1)
    echo sdui_log_format_pattern: "<%p>1 %d{ISO8601_WITH_TZ_OFFSET} %h SD %z %c - %m" >> $VARFILE
    if [[ $(id -u) != 0 ]]
    then
      sed -Ei 's:^\s*(node server/addons/plugins/hpesd/configuration/uoc-conf.js .*):sh -c "\1":' /opt/uoc2/scripts/setup_hpesd.sh
    fi
    ;;
esac

echo "Running configuration playbook..."
cd /docker/ansible
ansible-playbook config.yml -c local -i localhost, -e @$VARFILE || {
    echo "Service Director configuration failed. Container will stop now."
    exit 1
}
