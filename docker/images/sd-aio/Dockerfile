FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director AIO"
LABEL org.label-schema.description="Service Director All-in-One image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install PostgreSQL repository

RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf -qy module disable postgresql && \
    dnf clean all && rm -fr /var/cache/dnf

# Install dependencies for Service Provisioner

RUN dnf install -y \
                java-11-openjdk-devel \
                jq \
                python3 \
                python3-lxml \
                && \
    dnf clean all && rm -fr /var/cache/dnf

# Set Python 3.x as the default /usr/bin/python

RUN alternatives --set python /usr/bin/python3

# Install MUSE dependencies

RUN dnf module install -y nodejs:16/minimal -x npm && \
    dnf clean all && rm -fr /var/cache/dnf

# Install PostgreSQL

RUN dnf install -y postgresql11-server && \
    dnf clean all && rm -fr /var/cache/dnf

# Copy SD ISO contents

COPY ./iso /docker/iso

# Copy Ansible roles from ISO

COPY ./iso/AutomaticInstallation/roles /docker/ansible/roles

# Copy Ansible assets

COPY ./assets/ansible /docker/ansible

# Install components with Ansible

RUN cd /docker/ansible && \
    ansible-playbook -vvvv install.yml -c local -i localhost, -e ansible_service_mgr=sysvinit && \
    dnf clean all && rm -fr /var/cache/dnf && \
    rm -fr \
        /var/opt/OV/ServiceActivator/patch/* \
        /var/opt/OV/ServiceActivator/log/* \
    && \
    find /var/log -type f -delete

# Remove ISO contents from image

RUN rm -fr /docker/iso

# Copy PostgreSQL assets and configuration scripts

COPY ./assets/start_pgsql.sh /docker
COPY ./assets/stop_pgsql.sh /docker
COPY ./assets/scripts/setup/00_load_env.sh /docker/scripts/setup/00_load_env.sh
COPY ./assets/scripts/setup/01_config_pgsql.sh /docker/scripts/setup/01_config_pgsql.sh
COPY ./assets/scripts/setup/03_start_pgsql.sh /docker/scripts/setup/03_start_pgsql.sh

ARG prepared=false

# Configure PostgreSQL

ENV PGDATA=/pgdata
ENV PGPASSWORD=secret

# Copy init scripts

COPY ./assets/initscripts/kafka /etc/init.d/
COPY ./assets/initscripts/zookeeper /etc/init.d/
COPY ./assets/initscripts/activator /etc/init.d/

# Copy SD configuration script

COPY ./assets/scripts/setup/02_config_sd.sh /docker/scripts/setup/02_config_sd.sh

# Prepare image if requested

COPY ./assets/prepare.sh /docker/prepare.sh

RUN if test $prepared = true; then /docker/prepare.sh; fi

# Copy startup and healthcheck scripts

COPY ./assets/scripts/startup/00_load_env.sh /docker/scripts/startup/00_load_env.sh
COPY ./assets/startup.sh /docker/startup.sh
COPY ./assets/healthcheck.sh /docker/healthcheck.sh

EXPOSE 80
EXPOSE 8080
EXPOSE 162/udp

HEALTHCHECK --interval=1m --start-period=20m CMD /docker/healthcheck.sh

CMD /docker/startup.sh
