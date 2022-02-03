FROM sd-base-ansible

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

LABEL org.label-schema.schema-version=1.0
LABEL org.label-schema.name="Service Activator"
LABEL org.label-schema.description="Service Activator standalone image"
LABEL org.label-schema.vendor="Hewlett Packard Enterprise"

# Install dependencies for Service Activator

RUN dnf install -y \
                java-11-openjdk-devel \
                jq \
                && \
    dnf clean all && rm -fr /var/cache/dnf

# Copy Ansible roles

COPY ./dist/Ansible.tar.gz /docker/ansible/
RUN cd /docker/ansible; tar xf *.tar.gz roles && rm *.tar.gz

# Copy SA installation package

COPY ./dist/SAV91-1A*.zip /docker/ansible

# Copy Ansible assets

COPY ./assets/ansible /docker/ansible

# Install components with Ansible

RUN cd /docker/ansible && \
    ansible-playbook -vvvv install.yml -c local -i localhost, && \
    chmod -R o=u,a+w \
        /opt/OV/ServiceActivator \
        /etc/opt/OV/ServiceActivator \
        /var/opt/OV/ServiceActivator \
        /opt/HP/jboss \
    && \
    dnf clean all && rm -fr /var/cache/dnf && \
    rm -fr \
        /opt/HP/jboss/modules/system/layers/base/org/apache/logging/log4j/api/main/log4j-api-2.14.1.jar \
        /var/opt/OV/ServiceActivator/patch/*/backup \
        /var/opt/OV/ServiceActivator/patch/*/dist/product/* \
        /var/opt/OV/ServiceActivator/patch/*/log/* \
        /var/opt/OV/ServiceActivator/log/* \
        /var/log/*

# Remove SA installation package from image

RUN rm -fr /docker/ansible/SAV91-1A*.zip

# Copy init scripts

COPY ./assets/initscripts/activator /etc/init.d/

# Copy configuration, startup and healthcheck scripts

COPY ./assets/startup.sh /docker/
COPY ./assets/healthcheck.sh /docker/
COPY ./assets/logtail.sh /docker/
COPY ./assets/scripts /docker/scripts

EXPOSE 8080

HEALTHCHECK --interval=1m --start-period=10m CMD /docker/healthcheck.sh >/dev/null

CMD /docker/startup.sh
