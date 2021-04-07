FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Director Provisioning"
LABEL org.label-schema.description="Service Director Provisioning standalone image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install required dependencies

RUN dnf install -y \
                java-11-openjdk-devel \
                jq \
                python3 \
                python3-lxml \
                python3-pyyaml \
                && \
    dnf clean all && rm -fr /var/cache/dnf

# Set Python 3.x as the default /usr/bin/python

RUN alternatives --set python /usr/bin/python3

# Copy SD ISO contents

COPY ./iso /docker/iso

# Copy Ansible roles from ISO

COPY ./iso/AutomaticInstallation/roles /docker/ansible/roles

# Copy Ansible assets

COPY ./assets/ansible /docker/ansible

# Install components with Ansible

RUN cd /docker/ansible && \
    ansible-playbook -vvvv install.yml -c local -i localhost, && \
    chmod -R o=u,a+w \
    /opt/OV/ServiceActivator \
    /etc/opt/OV/ServiceActivator \
    /var/opt/OV/ServiceActivator \
    /opt/HP/jboss

# Remove ISO contents from image

RUN rm -fr /docker/iso

# Copy init scripts

COPY ./assets/initscripts/activator /etc/init.d/

# Copy configuration, startup and healthcheck scripts

COPY ./assets/startup.sh /docker/
COPY ./assets/healthcheck.sh /docker/
COPY ./assets/scripts /docker/scripts

EXPOSE 8080

HEALTHCHECK --interval=1m --start-period=10m CMD /docker/healthcheck.sh >/dev/null

CMD /docker/startup.sh
