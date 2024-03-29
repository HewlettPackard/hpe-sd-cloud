#!/bin/bash
# Docker build wrapper

set -e

################################################################################
# Configuration
################################################################################

# Name for the image to be built
IMGNAME=sd-base-ansible

# Base tag name
BASETAG=${BASETAG:-latest}

# Image version (based on date)
VERSION=${VERSION:-$(date +%Y%m%d)}

# Whether to not use cache when building the image
NOCACHE=${NOCACHE:-false}

# Whether to generate a squashed version of the image
SQUASH=${SQUASH:-false}

# Whether to tag the built image
TAG=${TAG:-true}

# Path to a file where the generated image id will be stored
IDFILE=${IDFILE:-}

# Whether to force pulling base image
PULL=${PULL:-true}

################################################################################
# Functions
################################################################################

function add_arg {
    build_args+=("$@")
}

################################################################################
# Main
################################################################################

# Disable squashing if not available
if [[ $SQUASH == true ]]; then
    experimental=$(docker version --format '{{.Server.Experimental}}')
    if [[ $experimental != true ]]; then
        echo "WARNING: Squashing images requires enabling experimental features for the Docker daemon."
        echo "More information here: https://docs.docker.com/engine/reference/commandline/dockerd/#description"
        echo
        echo "Squashing will be disabled now."
        SQUASH=false
    fi
fi

build_args=()

# Discard build cache if NOCACHE is specified
if [[ $NOCACHE == true ]]; then
    add_arg --no-cache
fi

# Force pulling base image if PULL is specified
if [[ $PULL == true ]]; then
    add_arg --pull
fi

# Save built image id to $IDFILE if specified
if [[ -n $IDFILE ]]; then
    idfile=$IDFILE
else
    idfile=$(mktemp)
fi
add_arg --iidfile "$idfile"

# Add build args for proxy environment variables
# This enables Internet access behind corporate proxy for intermediate containers
for v in HTTP_PROXY http_proxy HTTPS_PROXY https_proxy NO_PROXY no_proxy; do
    if [[ -v $v ]]; then
        add_arg --build-arg "$v=${!v}"
    fi
done

# Build
docker build "${build_args[@]}" .
id=$(cat "$idfile")
id_nonsquashed=$id

# Squash
if [[ $SQUASH == true ]]; then
    docker build "${build_args[@]}" --squash .
    id=$(cat "$idfile")
    id_squashed=$id
fi

# Remove ID file if not explicit
if [[ -z $IDFILE ]]; then
    rm -f "$idfile"
fi

if [[ $TAG == true ]]; then

# Tag image
if [[ $BASETAG == latest ]]; then
    docker tag $id $IMGNAME:$BASETAG
    tag_prefix=$VERSION
else
    tag_prefix=$BASETAG
fi

docker tag $id_nonsquashed $IMGNAME:$tag_prefix-nonsquashed

if [[ -n $id_squashed ]]; then
    docker tag $id_squashed $IMGNAME:$tag_prefix-squashed
fi

docker tag $id $IMGNAME:$tag_prefix

fi # [[ $TAG == true ]]
