# Building Grok Exporter

To expose some SD Provisioning logs as standard metrics for Prometheus we use Grok Exporter as a sidecar container inside SD Provisioning pod.

[Grok exporter](https://github.com/fstab/grok_exporter) does not have an official Docker image distribution, therefore in order to use you have to generate your own Docker image. A Dockerfile an all the files needed are included in the [grokexporter\docker](./grokexporter/docker/) subfolder to help you with that.

Running the following command from the [grokexporter\docker](./grokexporter/docker/) subfolder will generate de Docker image:

    docker build -t grok_exporter:latest .
