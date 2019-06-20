FROM centos:7

LABEL maintainer="Guillermo Jano <guillermo.jano@hpecds.com>"

# Install base dependencies incl. Ansible

RUN yum -y update && \
    yum install -y epel-release && \
    yum install -y \
                ansible \
                bzip2 \
                initscripts \
                libselinux-python \
                patch \
                python-pip \
                unzip \
                && \
    yum clean all && rm -rf /var/cache/yum

RUN pip install --no-cache-dir pexpect
