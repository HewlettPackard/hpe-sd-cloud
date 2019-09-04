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

echo "Running configuration playbook..."
cd /docker/ansible && ansible-playbook sp_configure.yml -i inventory -e @$VARFILE || {
    echo "Service Director configuration failed. Container will stop now."
    exit 1
}

echo . /opt/OV/ServiceActivator/bin/setenv > /etc/profile.d/activator.sh
. /etc/profile.d/activator.sh

# Install license if present

LICENSEFILE=${LICENSEFILE:-/license}

if [[ -f $LICENSEFILE ]]
then
  echo "Found license file at $LICENSEFILE"
  $ACTIVATOR_OPT/bin/updateLicense -f $LICENSEFILE
else
  echo "Did not find license file"
  # Generate Instant On license if missing
  $ACTIVATOR_OPT/bin/updateLicense 1
  $ACTIVATOR_OPT/bin/updateLicense 1 -dde
fi

# Disable IPv6, otherwise WidlFly does not start

echo JAVA_OPTS='"$JAVA_OPTS -Djava.net.preferIPv4Stack=true"' >> $JBOSS_HOME/bin/standalone.conf
