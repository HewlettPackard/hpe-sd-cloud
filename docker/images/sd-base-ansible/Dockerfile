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
    dnf clean all && rm -fr /var/cache/dnf
