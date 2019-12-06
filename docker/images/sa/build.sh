#!/bin/bash
# Docker build wrapper

set -e

################################################################################
# Configuration
################################################################################

DIST_PATH=dist

# Name for the image to be built
IMGNAME=sa

# SD version the image is based on
SAVERSION=9.0.3

# Base tag name
BASETAG=${BASETAG:-latest}

# Whether to not use cache when building the image
NOCACHE=${NOCACHE:-false}

# Whether to generate a squashed version of the image
SQUASH=${SQUASH:-false}

# Whether to tag the built image
TAG=${TAG:-true}

# Whether to generate a squashed version of the image
IDFILE=${IDFILE:-}

# Proxy configuration
# Will use current environment configuration if available
HTTP_PROXY=${HTTP_PROXY:-}
HTTPS_PROXY=${HTTPS_PROXY:-$HTTP_PROXY}
NO_PROXY=${NO_PROXY:-}
http_proxy=${http_proxy:-$HTTP_PROXY}
https_proxy=${https_proxy:-$HTTPS_PROXY}
no_proxy=${no_proxy:-$NO_PROXY}

################################################################################
# Functions
################################################################################

function check_iso {
    if ! stat \
        $DIST_PATH/Ansible/roles \
        $DIST_PATH/HPSA-V90-1A.x86_64.rpm \
        $DIST_PATH/SAV90-1A-*.zip \
        >/dev/null 2>&1
    then
        echo "Could not find the expected distribution files."
        echo "Make sure distribution files are properly placed inside the 'dist' directory."
        exit 1
    fi

    pkgmatches=$(find $DIST_PATH -maxdepth 1 -name "SAV90-1A-*.zip" -printf '.'|wc -m)
    if [[ $pkgmatches -gt 1 ]]
    then
        echo "Multiple hotfix packages found inside the 'dist' directory."
        echo "Please ensure only the right hotfix package is present."
        exit 1
    fi
}

function check_ansible {
    if [[ ! -d ansible/roles ]]
    then
        echo "Could not find roles in the product Ansible repo."
        echo "Make sure you have properly initialized submodules."
        echo
        echo "In order to initialize submodules issue the following commands:"
        echo
        echo "  - git submodule init"
        echo "  - git submodule update"
        echo
        echo "Then try building the image again."
        exit 1
    fi
}

function add_arg {
    build_args+=("$@")
}

################################################################################
# Main
################################################################################

# Ensure required directories exist
mkdir -p iso

# Check ISO is mounted
check_iso

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

# Save built image id to $IDFILE if specified
if [[ -n $IDFILE ]]; then
    idfile=$IDFILE
else
    idfile=$(mktemp)
fi
add_arg --iidfile "$idfile"

# Add VCS reference if available
if git describe --always >/dev/null 2>&1; then
    ref=$(git describe --tags --always --dirty)
    add_arg --label "org.label-schema.vcs-ref=$ref"
fi

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
    tag_prefix=$SAVERSION
else
    tag_prefix=$BASETAG
fi

docker tag $id_nonsquashed $IMGNAME:$tag_prefix-nonsquashed

if [[ -n $id_squashed ]]; then
    docker tag $id_squashed $IMGNAME:$tag_prefix-squashed
fi

docker tag $id $IMGNAME:$tag_prefix

fi # [[ $TAG == true ]]
