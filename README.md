# Service Director in the Cloud

This repository contains assets related to deployment of the HPE Service Director (SD) product in a cloud environment. SD uses service modeling innovation to automate dynamic services orchestration end-to-end across hybrid physical and virtualized networks.

Assets are organized in directories per topic. Each directory is briefly explained below, and in more detail in README files within each directory.

All assets are made available as is using an MIT license, see [LICENSE](LICENSE).

A prerequisite to building Docker images is the ISO image for SD. This is only available commercially. Please contact your local HPE representative for this.

## Directory Index

- [contrib](contrib): This directory will hold external contributions to the SD cloudification effort, including examples, guides, etc.
- [docker](docker): This directory contains specifications (`Dockerfile`s) for building Docker images for Service Director components. Building requires access to a Service Director ISO image and an appropriate commercial license. Utility wrapper scripts are included to ease building although using standard Docker tools is possible as well. Also some usage examples (docker compose) involving such images are included in here as well.
- [kubernetes](kubernetes): In this directory you can find a full Helm Chart sample for the Service Director deployment into kubernetes cluster, including integration with Redis, Prometheus and ElasticSearch. Further it includes kubernetes deployment examples for SD.


## Contact

If you have any questions regarding the contents, or would like to contribute, please contact Thomas Mortensen, thomas.mortensen (at) hpe.com or Andres Duebi, andres.duebi (at) hpe.com or Jens Vedel Markussen, jens.markussen (at) hpe.com.
