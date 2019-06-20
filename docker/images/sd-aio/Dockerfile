FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director AIO"
LABEL org.label-schema.description="Service Director All-in-One image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install Oracle XE 18c preinstall RPM

RUN yum install -y https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm && \
    yum clean all && rm -rf /var/cache/yum

# Install dependencies for Service Provisioner

RUN yum install -y \
                dos2unix \
                java-1.8.0-openjdk-devel \
                ksh \
                sharutils \
                && \
    yum clean all && rm -rf /var/cache/yum

# Install dependencies for UOC

RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -

ADD ./assets/couchdb/repo /etc/yum.repos.d/bintray-apache-couchdb-rpm.repo

RUN yum install -y \
                couchdb \
                fontconfig \
                freetype \
                nodejs \
                && \
    yum clean all && rm -rf /var/cache/yum

# Install Oracle XE

COPY ./kits/oracle-database-xe-18c-*.rpm /tmp/rpms/

ENV ORACLE_DOCKER_INSTALL=true

RUN yum install -y /tmp/rpms/oracle-database-xe-18c-*.rpm && \
    rm /tmp/rpms/oracle-database-xe-18c-*.rpm && \
    yum clean all && rm -rf /var/cache/yum

# Copy SD ISO contents

COPY ./iso /docker/iso

# Copy Ansible roles from repository (this is needed until the ISO is Docker-ready)

COPY ./iso/AutomaticInstallation/roles /docker/ansible/roles

# Copy playbooks and inventories

COPY ./iso/AutomaticInstallation/inventories/eventcollection/group_vars/all /docker/ansible/inventories/eventcollection/group_vars/
COPY ./iso/AutomaticInstallation/inventories/monitoring/group_vars/all /docker/ansible/inventories/monitoring/group_vars/
COPY ./iso/AutomaticInstallation/inventories/provisioning-orcl/group_vars/all /docker/ansible/inventories/provisioning/group_vars/
COPY ./iso/AutomaticInstallation/inventories/uoc/group_vars/all /docker/ansible/inventories/uoc/group_vars/
COPY ./assets/ansible /docker/ansible

# Install event collection framework

COPY ./assets/initscripts/kafka /etc/init.d/
COPY ./assets/initscripts/zookeeper /etc/init.d/

RUN cd /docker/ansible && ansible-playbook -vvvv eventcollection_install.yml -i inventories/eventcollection

# Install Provisioning

RUN cd /docker/ansible && ansible-playbook -vvvv sp_install.yml -i inventories/provisioning

# Install SNMP adapter

RUN cd /docker/ansible && ansible-playbook -vvvv monitoring_install.yml -i inventories/monitoring

# Install UI

RUN cd /docker/ansible && ansible-playbook -vvvv ui_install.yml -i inventories/uoc

# Copy Oracle XE response files

COPY ./assets/oraclexe/oracle-xe-18c.conf /docker/oraclexe/oracle-xe-18c.conf
COPY ./assets/oraclexe/XE_Database.dbc /opt/oracle/product/18c/dbhomeXE/assistants/dbca/templates/XE_Database.dbc
COPY ./assets/oraclexe/profile /docker/oraclexe/profile

ARG prepared=false

# Configure Oracle XE

COPY ./assets/initscripts/oracle-xe-18c /etc/init.d/
COPY ./assets/configure_oraclexe.sh /docker/configure_oraclexe.sh
COPY ./assets/start_oraclexe.sh /docker/start_oraclexe.sh
COPY ./assets/start_oraclexe.sh /docker/stop_oraclexe.sh

RUN if test $prepared = true; then /docker/configure_oraclexe.sh && rm /docker/configure_oraclexe.sh && /docker/stop_oraclexe.sh; fi

# Copy CouchDB init script

COPY ./assets/initscripts/couchdb /etc/init.d/

# Configure SD

COPY ./assets/configure_sd.sh /docker/configure_sd.sh

RUN if test $prepared = true; then /docker/configure_sd.sh && rm /docker/configure_sd.sh && /docker/stop_oraclexe.sh; fi

# Copy startup script

COPY ./assets/startup.sh /docker/startup.sh
COPY ./assets/healthcheck.sh /docker/healthcheck.sh

EXPOSE 8081
EXPOSE 3000
EXPOSE 162/udp

HEALTHCHECK --interval=1m --start-period=20m CMD /docker/healthcheck.sh

CMD /docker/startup.sh
