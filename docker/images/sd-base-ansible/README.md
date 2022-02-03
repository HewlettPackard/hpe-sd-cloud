# HPE SD Base Ansible image

This is just a base image serving as the foundation for all Ansible-based HPE Service Director images. It is based on [`almalinux:8`](https://hub.docker.com/_/almalinux) and includes Ansible plus Python modules required by Ansible modules being used in HPE SD roles plus some dependencies common to all images.

## Usage

This image is not meant to be instantiated, but it serves as the base for other images.

## Building the HPE SD Base Ansible image

### Using the build-wrapper script

To simplify the build process, a build-wrapper script (`build.sh`) is provided. This script builds the image and tags it as `sd-base-ansible`.

To build the image behind a corporate proxy, it is necessary to define the appropriate proxy environment variables. By default, these variables are specified by the build-wrapper script. To use a different proxy, define the variables as appropriate in your environment.

### Building the image manually

If you want to build the image manually, you can use the following command:

```
docker build -t sd-base-ansible .
```

If you are behind a proxy, use the following command:

```
docker build -t sd-base-ansible \
    --build-arg HTTP_PROXY=http://your.proxy.server:8080 \
    --build-arg http_proxy=http://your.proxy.server:8080 \
    --build-arg HTTPS_PROXY=http://your.proxy.server:8080 \
    --build-arg https_proxy=http://your.proxy.server:8080 \
    --build-arg NO_PROXY=localhost,127.0.0.1,.your.domain.com \
    --build-arg no_proxy=localhost,127.0.0.1,.your.domain.com \
    .
```

### Versioning

The build-wrapper script tags the image as `sd-base-ansible:latest` and `sd-base-ansible:$date`, for example, `sd-base-ansible:20180712`. Versioning the base image this way makes sense because it basically runs `yum` and `pip` to install packages and modules, and the end result depends on when the image was built. For example, on 12 July 2018, Ansible 2.6.0 was installed, but today, a newer version would be installed.

