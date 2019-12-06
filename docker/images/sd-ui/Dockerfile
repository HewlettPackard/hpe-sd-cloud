FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director UI"
LABEL org.label-schema.description="Service Director UI standalone image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install dependencies for UOC

RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -

ADD ./assets/couchdb/repo /etc/yum.repos.d/bintray-apache-couchdb-rpm.repo

RUN yum install -y \
                couchdb \
                fontconfig \
                freetype \
                jq \
                nodejs \
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

# Copy init scripts

COPY ./assets/initscripts/couchdb /etc/init.d

# Copy startup scripts

COPY ./assets/configure_ui.sh /docker/
COPY ./assets/startup.sh /docker/
COPY ./assets/healthcheck.sh /docker/

EXPOSE 3000

HEALTHCHECK --interval=1m --start-period=10m CMD /docker/healthcheck.sh >/dev/null

CMD /docker/startup.sh
