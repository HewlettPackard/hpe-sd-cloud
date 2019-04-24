SD Base Ansible Image
=====================

This is just a base image serving as the foundation for all Ansible-based Service Director images. It is based on `centos:7` and includes Ansible plus Python modules required by Ansible modules being used in SD roles plus some dependencies common to all images.

Usage
-----

This image is not meant to be instantiated but instead serves as the bases for other images.

Building
--------

In order to ease building a build-wrapper script `build.sh` script is provided. This script will build the image and tag it as `sd-base-ansible`.

In order to build the image behind a corporate proxy it is necessary to define the appropriate proxy environment variables. Such variables are specified by default by the build-wrapper script. In order to use a different proxy just define them as appropriate in your environment.

If you want to build the image by hand, you can use the following:

    docker build -t sd-base-ansible .

or if you are behind a proxy:

    docker build -t sd-base-ansible \
        --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
        --build-arg http_proxy=http://your.proxy.server:8080 \
        --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
        --build-arg https_proxy=http://your.proxy.server:8080 \
        --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
        --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
        .

When using the script the image will be tagged as `sd-base-ansible:latest` as well as `sd-base-ansible:$date` e.g. `sd-base-ansible:20180712`. Versioning the base image like this makes sense since it basically runs `yum` and `pip` to install packages/modules and so the end result will depend on when the image was built, e.g. as of 2018-07-12 Ansible 2.6.0 will be installed but probably in a few months it would be a newer version instead.