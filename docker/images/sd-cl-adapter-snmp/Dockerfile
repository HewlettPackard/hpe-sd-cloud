FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director SNMP adapter"
LABEL org.label-schema.description="Service Director SNMP adapter standalone image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install dependencies for SNMP adapter

RUN yum install -y \
                java-1.8.0-openjdk-devel \
                && \
    yum clean all && rm -rf /var/cache/yum

# Copy SD ISO binaries

COPY ./iso/Binaries /docker/iso/Binaries

# Copy Ansible roles, playbooks and inventories

COPY ./iso/AutomaticInstallation/roles /docker/ansible/roles
COPY ./iso/AutomaticInstallation/inventories/monitoring/group_vars/all /docker/ansible/inventory/group_vars/
COPY ./assets/ansible /docker/ansible

# Run playbook

RUN cd /docker/ansible && ansible-playbook -vvvv adapter_install.yml -i inventory

# Remove ISO contents from image

RUN rm -fr /docker/iso

# Copy startup scripts

COPY ./assets/configure_adapter.sh /docker/
COPY ./assets/startup.sh /docker/
COPY ./assets/healthcheck.sh /docker/

RUN sed -i '/sd-asr-setup-adapter.sh enable/a \ \ when: no' /docker/ansible/roles/ansible-role-asr-adapters-configure/tasks/main.yml

EXPOSE 162/udp

HEALTHCHECK --interval=1m --start-period=1m CMD /docker/healthcheck.sh >/dev/null

CMD /docker/startup.sh
