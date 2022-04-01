echo "Configuring Service Director..."

build_ansible_varfile

# Remove mwfm.xml to force ActivatorConfig re-run
rm -f /etc/opt/OV/ServiceActivator/config/mwfm.xml

echo "Running configuration playbook..."
cd /docker/ansible
ansible-playbook config.yml -c local -i localhost, -e @$VARFILE || {
    echo "Service Director configuration failed. Container will stop now."
    exit 1
}

. /opt/OV/ServiceActivator/bin/setenv

# Install license if present

LICENSEFILE=${LICENSEFILE:-/license}

if [[ -f $LICENSEFILE ]]
then
  echo "Found license file at $LICENSEFILE"
  "$ACTIVATOR_OPT/bin/updateLicense" -f "$LICENSEFILE"
fi

if [[ $(sysctl -ne net.ipv6.conf.lo.disable_ipv6) != 0 ]]
then
    echo JAVA_OPTS='"$JAVA_OPTS -Djava.net.preferIPv4Stack=true"' >> "$JBOSS_HOME/bin/standalone.conf"
fi

# Experimental RFC5424 mode

case $EXPERIMENTAL_RFC5424_MODE in
  yes|YES|true|TRUE|True|1)
logPattern="<%p>1 %d{yyyy-MM-dd}T%d{HH:mm:ss.SSSXXX} %H SA %X{TRACEID} - - %s%e%n"

# Update WildFly logging subsystem configuration

$JBOSS_HOME/bin/jboss-cli.sh <<EOF
embed-server
/subsystem=logging/pattern-formatter=PATTERN:write-attribute(name=pattern,value="$logPattern")
stop-embedded-server
quit
EOF

# Update boot logging configuration to ensure RFC5424 is used from the start

sed -i "/^formatter\.PATTERN\.pattern=/d" /opt/HP/jboss/standalone/configuration/logging.properties
echo formatter\.PATTERN\.pattern=$logPattern >> /opt/HP/jboss/standalone/configuration/logging.properties

# Wipe server.log to discard non-RFC5424-conformant traces from setup phase
# Otherwise they might be displayed once we start tailing

rm $JBOSS_HOME/standalone/log/server.log
;;
esac
