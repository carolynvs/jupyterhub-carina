#!/bin/bash
set -euo pipefail

# Figure out the current directory
__SCRIPT_SOURCE="$_"
if [ -n "$BASH_SOURCE" ]; then
  __SCRIPT_SOURCE="${BASH_SOURCE[0]}"
fi
SCRIPT_DIR="$(cd "$(dirname "${__SCRIPT_SOURCE:-$0}")" > /dev/null && \pwd)"
unset __SCRIPT_SOURCE 2> /dev/null

# Load secret credentials
source $SCRIPT_DIR/secrets.sh

# Load settings
source $SCRIPT_DIR/settings.sh

# Connect to the Carina cluster
eval $(carina env $JUPYTERHUB_CLUSTER)

# Cleanup old containers
docker rm -f nginx jupyterhub letsencrypt website &> /dev/null || true

# Build and publish the custom Docker image used by the user's Jupyter server
docker build -f $SCRIPT_DIR/Dockerfile-jupyter -t $JUPYTER_IMAGE $SCRIPT_DIR
docker push $JUPYTER_IMAGE

# Do all the things with a sidecar of stuff
docker-compose -f $SCRIPT_DIR/docker-compose.yml build
docker-compose -f $SCRIPT_DIR/docker-compose.yml up -d
docker-compose -f $SCRIPT_DIR/docker-compose.yml logs -f
