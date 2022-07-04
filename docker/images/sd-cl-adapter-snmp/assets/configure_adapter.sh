echo "Configuring Service Director..."

build_ansible_varfile

echo "Running configuration playbook..."
cd /docker/ansible
ansible-playbook config.yml -c local -i localhost, -e ansible_service_mgr=sysvinit -e @$VARFILE || {
    echo "Service Director configuration failed. Container will stop now."
    exit 1
}

sed -i "s/pgrep -u root/pgrep/g" /opt/sd-asr/adapter/bin/sd-asr-SNMPGenericAdapter_1.sh
