#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -ex

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )

# Load all variables
source $REPO_DIR/build/__variables.sh
source $REPO_DIR/build/__functions.sh
source $REPO_DIR/build/__nodeVersions.sh
source $REPO_DIR/build/__baseImageTags.sh

runtimeImagesSourceDir="$RUNTIME_IMAGES_SRC_DIR"
runtimeSubDir="$1"
if [ ! -z "$runtimeSubDir" ]
then
    runtimeImagesSourceDir="$runtimeImagesSourceDir/$runtimeSubDir"
    if [ ! -d "$runtimeImagesSourceDir" ]; then
        (>&2 echo "Unknown runtime '$runtimeSubDir'")
        exit 1
    fi
fi

labels="--label com.microsoft.oryx.git-commit=$GIT_COMMIT"
labels="$labels --label com.microsoft.oryx.build-number=$BUILD_NUMBER"

execAllGenerateDockerfiles "$runtimeImagesSourceDir"

dockerFileName="Dockerfile.base"
dockerFiles=$(find $runtimeImagesSourceDir -type f -name $dockerFileName)
if [ -z "$dockerFiles" ]
then
    echo "Couldn't find any Dockerfiles with name '$dockerFileName' under '$runtimeImagesSourceDir' and its sub-directories."
    exit 1
fi

# Write the list of images that were built to artifacts folder
mkdir -p "$BASE_IMAGES_ARTIFACTS_FILE_PREFIX"

# NOTE: We create a unique artifacts file per platform since they are going to be built in parallel on CI
ARTIFACTS_FILE="$BASE_IMAGES_ARTIFACTS_FILE_PREFIX/$runtimeSubDir-runtimeimage-bases.txt"

initFile="$runtimeImagesSourceDir/buildRunTimeImageBases_Init.sh"
if [ -f "$initFile" ]; then
    $initFile
fi

clearedOutput=false
for dockerFile in $dockerFiles; do
    dockerFileDir=$(dirname "${dockerFile}")

    # Set $getTagName_result to the following format: {platformName}:{platformVersion}
    getTagName $dockerFileDir

    IFS=':' read -ra PARTS <<< "$getTagName_result"
    platformName="${PARTS[0]}"
    platformVersion="${PARTS[1]}"

    # Set $localImageTagName to the following format: oryxdevmcr.azurecr.io/public/oryx/base:{platformName}-{platformVersion}
    localImageTagName="$BASE_IMAGES_REPO:$platformName-$platformVersion"

    echo
    echo "Building image '$localImageTagName' for Dockerfile located at '$dockerFile'..."

    cd $REPO_DIR

    echo
    docker build -f $dockerFile \
        -t $localImageTagName \
        --build-arg CACHEBUST=$(date +%s) \
        --build-arg NODE6_VERSION=$NODE6_VERSION \
        --build-arg NODE8_VERSION=$NODE8_VERSION \
        --build-arg NODE10_VERSION=$NODE10_VERSION \
        --build-arg NODE12_VERSION=$NODE12_VERSION \
        --build-arg ORYX_RUNTIME_BASE="-$ORYX_RUNTIME_BASE" \
        --build-arg DOT_NET_CORE_RUNTIME_BASE_TAG="-$DOT_NET_CORE_RUNTIME_BASE_TAG" \
        --build-arg PHP_RUNTIME_BASE_TAG="-$PHP_RUNTIME_BASE_TAG" \
        --build-arg NODE_RUNTIME_BASE_TAG="-$NODE_RUNTIME_BASE_TAG" \
        $labels \
        .

    # Retag build image with build numbers as ACR tags
    if [ "$AGENT_BUILD" == "true" ]
    then
        # $tag will follow a similar format to 20191024.1
        uniqueImageName="$localImageTagName-$BUILD_NUMBER"

        # Tag the image to follow a similar format to .../python:3.7-20191028.1
        docker tag "$localImageTagName" "$uniqueImageName"

        if [ $clearedOutput == "false" ]
        then
            # clear existing contents of the file, if any
            > $ARTIFACTS_FILE
            clearedOutput=true
        fi

        # add new content
        echo
        echo "Updating artifacts file with the built runtime image information..."
        echo "$uniqueImageName" >> $ARTIFACTS_FILE
    fi

    cd $RUNTIME_IMAGES_SRC_DIR
done

if [ "$AGENT_BUILD" == "true" ]
then
    echo
    echo "List of images tagged (from '$ARTIFACTS_FILE'):"
    cat $ARTIFACTS_FILE
fi

echo
showDockerImageSizes

echo
dockerCleanupIfRequested
