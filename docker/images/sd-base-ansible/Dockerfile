FROM almalinux:8

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

# Install base dependencies incl. Ansible

RUN dnf -y update && \
    dnf install -y epel-release && \
    dnf install -y \
                ansible \
                bzip2 \
                initscripts \
                patch \
                sudo \
                unzip \
                && \
    rpm -Uvh --nodeps \
        $(dnf repoquery --location nss_wrapper --arch $(uname -m)) && \
    dnf clean all && rm -fr /var/cache/dnf

ENV HOME /docker/home

RUN mkdir -m 777 /docker /docker/ansible /docker/ansible/tmp /docker/home

COPY ./assets/common.sh /docker/

COPY ./assets/ansible.cfg /etc/ansible/
