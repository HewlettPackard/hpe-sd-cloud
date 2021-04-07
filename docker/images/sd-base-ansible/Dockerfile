FROM centos:8

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

# Install base dependencies incl. Ansible

RUN dnf -y update && \
    dnf install -y centos-release-ansible-29 && \
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

RUN mkdir -m 777 /docker /docker/ansible /docker/ansible/tmp

COPY ./assets/rootless.sh /docker/

COPY ./assets/ansible.cfg /etc/ansible/
