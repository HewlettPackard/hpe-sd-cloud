FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director Provisioning"
LABEL org.label-schema.description="Service Director Provisioning standalone image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install dependencies for Service Provisioner

RUN yum install -y \
                dos2unix \
                java-1.8.0-openjdk-devel \
                ksh \
                sharutils \
                && \
    yum clean all && rm -rf /var/cache/yum

# Copy SD ISO contents

COPY ./iso /docker/iso

# Copy Ansible roles from repository (this is needed until the ISO is Docker-ready)

COPY ./iso/AutomaticInstallation/roles /docker/ansible/roles

# Copy playbooks and inventories

COPY ./iso/AutomaticInstallation/inventories/provisioning-orcl/group_vars/all /docker/ansible/inventory/group_vars/
COPY ./assets/ansible /docker/ansible

# Install Provisioning

RUN sed -i '/service:/a \ \ when: no' /docker/ansible/roles/ansible-role-kafka-install/tasks/main.yml

RUN cd /docker/ansible && ansible-playbook -vvvv sp_install.yml -i inventory

# Remove ISO contents from image

RUN rm -fr /docker/iso

# Copy startup script

COPY ./assets/configure_sp.sh /docker/
COPY ./assets/startup.sh /docker/
COPY ./assets/healthcheck.sh /docker/

EXPOSE 8081

HEALTHCHECK --interval=1m --start-period=10m CMD /docker/healthcheck.sh >/dev/null

CMD /docker/startup.sh
