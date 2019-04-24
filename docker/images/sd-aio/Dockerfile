FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpcds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director AIO"
LABEL org.label-schema.description="Service Director All-in-One image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install dependencies for Oracle XE

RUN yum install -y \
                bc \
                libaio \
                net-tools \
                openssl \
                && \
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

RUN yum install -y \
                fontconfig \
                freetype \
                nodejs \
                && \
    yum clean all && rm -rf /var/cache/yum

# Install Oracle XE

COPY ./kits/oracle-xe-*.rpm /tmp/rpms/

RUN cat() { declare -A PROC=(["/proc/sys/kernel/shmmax"]=4294967295 ["/proc/sys/kernel/shmmni"]=4096 ["/proc/sys/kernel/shmall"]=2097152 ["/proc/sys/fs/file-max"]=6815744); [[ ${PROC[$1]} == "" ]] && /usr/bin/cat $* || echo ${PROC[$1]}; } && \
    free() { echo "Swap: 2048 0 2048"; } && \
    export -f cat free && \
    rpm -i /tmp/rpms/oracle-xe-*.rpm && \
    unset -f cat free && \
    rm /tmp/rpms/oracle-xe-*.rpm

# Copy SD ISO contents

COPY ./iso /docker/iso

# Copy Ansible roles from repository (this is needed until the ISO is Docker-ready)

COPY ./iso/AutomaticInstallation/roles /docker/ansible/roles

# Copy playbooks and inventories

COPY ./iso/AutomaticInstallation/inventories/provisioning-orcl/group_vars/all /docker/ansible/inventories/provisioning/group_vars/
COPY ./iso/AutomaticInstallation/inventories/uoc/group_vars/all /docker/ansible/inventories/uoc/group_vars/
COPY ./assets/ansible /docker/ansible

# Install Provisioning

RUN cd /docker/ansible && ansible-playbook -vvvv sp_install.yml -i inventories/provisioning

# Install UI

COPY ./kits/couchdb-*.x86_64.rpm /docker/ansible/
COPY ./kits/js-*.x86_64.rpm /docker/ansible/

RUN cd /docker/ansible && ansible-playbook -vvvv ui_install.yml -i inventories/uoc

# Cleanup

RUN rm -rf /tmp/rpms /docker/iso /docker/ansible/*.rpm

# Copy Oracle XE response file

COPY ./assets/oraclexe/xe.rsp /docker/oraclexe/xe.rsp

ARG prepared=false

# Configure Oracle XE

COPY ./assets/configure_oraclexe.sh /docker/configure_oraclexe.sh
COPY ./assets/start_oraclexe.sh /docker/start_oraclexe.sh

RUN if test $prepared = true; then /docker/configure_oraclexe.sh && rm /docker/configure_oraclexe.sh; fi

# Configure SD

COPY ./assets/configure_sd.sh /docker/configure_sd.sh

# Copy init scripts

COPY ./assets/initscripts/* /etc/init.d

RUN if test $prepared = true; then /docker/configure_sd.sh && rm /docker/configure_sd.sh; fi

# Copy startup script

COPY ./assets/startup.sh /docker/startup.sh
COPY ./assets/healthcheck.sh /docker/healthcheck.sh

EXPOSE 8081
EXPOSE 3000

HEALTHCHECK --interval=1m --start-period=10m CMD /docker/healthcheck.sh

CMD /docker/startup.sh
