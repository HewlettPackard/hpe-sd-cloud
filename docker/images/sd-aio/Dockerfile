FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director AIO"
LABEL org.label-schema.description="Service Director All-in-One image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install EDB repository

RUN yum install -y https://yum.enterprisedb.com/edbrepos/edb-repo-latest.noarch.rpm && \
    yum clean all && rm -rf /var/cache/yum

ARG EDB_YUM_USERNAME
ARG EDB_YUM_PASSWORD

RUN sed -i "s,<username>,$EDB_YUM_USERNAME,g" /etc/yum.repos.d/edb.repo && \
    sed -i "s,<password>,$EDB_YUM_PASSWORD,g" /etc/yum.repos.d/edb.repo

# Install dependencies for Service Provisioner

RUN yum install -y \
                java-11-openjdk-devel \
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

# Install EDB

RUN yum install -y \
                --enablerepo=edbas11 \
                --enablerepo=enterprisedb-tools \
                --enablerepo=enterprisedb-dependencies \
                edb-as11-server \
                && \
    yum clean all && rm -rf /var/cache/yum

# Copy SD ISO contents

COPY ./iso /docker/iso

# Copy Ansible roles from ISO

COPY ./iso/AutomaticInstallation/roles /docker/ansible/roles

# Copy Ansible assets

COPY ./assets/ansible /docker/ansible

# Install components with Ansible

RUN cd /docker/ansible && ansible-playbook -vvvv install.yml -c local -i localhost,

# Remove ISO contents from image

RUN rm -fr /docker/iso

# Copy EDB assets

COPY ./assets/start_edb.sh /docker
COPY ./assets/stop_edb.sh /docker
COPY ./assets/configure_edb.sh /docker

ARG prepared=false

# Configure EDB

ENV PGDATA=/pgdata
ENV PGPASSWORD=secret

RUN if test $prepared = true; then /docker/configure_edb.sh && rm /docker/configure_edb.sh && /docker/stop_edb.sh; fi

# Copy init scripts

COPY ./assets/initscripts/couchdb /etc/init.d/
COPY ./assets/initscripts/kafka /etc/init.d/
COPY ./assets/initscripts/zookeeper /etc/init.d/
COPY ./assets/initscripts/activator /etc/init.d/

# Configure SD

COPY ./assets/configure_sd.sh /docker/configure_sd.sh

RUN if test $prepared = true; then /docker/configure_sd.sh && rm /docker/configure_sd.sh && /docker/stop_edb.sh; fi

# Copy startup and healthcheck scripts

COPY ./assets/startup.sh /docker/startup.sh
COPY ./assets/healthcheck.sh /docker/healthcheck.sh

EXPOSE 8080
EXPOSE 3000
EXPOSE 162/udp

HEALTHCHECK --interval=1m --start-period=20m CMD /docker/healthcheck.sh

CMD /docker/startup.sh
