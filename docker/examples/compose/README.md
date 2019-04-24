# Docker Compose Example Scenarios

This directory contains Docker Compose example scenarios based on official Service Director Docker images. Each subdirectory corresponds to a different scenario, with its corresponding `docker-compose.yml` file and a README. Check those for specific details on each particular configuration.

In order to install Docker Compose you may check [Install Docker Compose](https://docs.docker.com/compose/install) from the official Docker website.

Note that examples in this directory assume you have images built locally, so they are referenced by their base repository name, e.g. `sd-sp` or `sd-ui`. If you are instead pulling images from a registry, you need to either tag them locally or replace references, e.g. `sd-sp` would become `$REGISTRY/path/sd-sp`.