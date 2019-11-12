#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -ex

buildArgs=""
if [ -n "$1" ]
then
    echo
    echo "Setting 'REPO_PREFIX' build arg to '$1'."
    buildArgs="--build-arg $1"
fi

if [ -n "$2" ]
then
    echo
    echo "Setting 'TAG' build arg to '$2'."
    buildArgs="$buildArgs --build-arg $2"
fi

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )

# Load all variables
source $REPO_DIR/build/__variables.sh
source $REPO_DIR/build/__functions.sh

echo
echo Building build images for tests...
docker build \
    -t $ORYXTESTS_BUILDIMAGE_REPO \
    -f "$ORYXTESTS_BUILDIMAGE_DOCKERFILE" \
    $buildArgs \
    .

docker build \
    -t $ORYXTESTS_SLIM_BUILDIMAGE_REPO \
    -f "$ORYXTESTS_SLIM_BUILDIMAGE_DOCKERFILE" \
    $buildArgs \
    .

echo
dockerCleanupIfRequested
