#!/bin/bash

set -ex

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd ../.. && pwd )
declare -r SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source $REPO_DIR/build/__variables.sh

labels="--label com.microsoft.oryx.git-commit=$GIT_COMMIT"
labels="$labels --label com.microsoft.oryx.build-number=$BUILD_NUMBER"
labels="$labels --label com.microsoft.oryx.release-tag-name=$RELEASE_TAG_NAME"

repoName="oryxmcr.azurecr.io/public/oryx/base"
artifactsFile="$REPO_DIR/artifacts/baseImages.txt"

cd "$REPO_DIR"

function buildImage() {
    local dockerFile="$1"
    local imageName="$2"
    
    echo
    echo "Building image '$imageName'..."
    docker build \
        $labels \
        -f "$dockerFile" \
        -t "$imageName" \
        .

    withSpecificTag="$imageName-$RELEASE_TAG_NAME"
    docker tag "$imageName" "$withSpecificTag"
    echo "$withSpecificTag" >> "$artifactsFile" 
}

mkdir -p "$REPO_DIR/artifacts"

buildImage \
    "$REPO_DIR/images/common/buildpack-deps-stretch.Dockerfile" \
    "$repoName:buildpack-deps-stretch"

buildImage \
    "$REPO_DIR/images/common/buildpack-deps-stretch-curl.Dockerfile" \
    "$repoName:buildpack-deps-stretch-curl"

buildImage \
    "$REPO_DIR/images/common/buildpack-deps-buster.Dockerfile" \
    "$repoName:buildpack-deps-buster"

buildImage \
    "$REPO_DIR/images/common/buildpack-deps-buster-curl.Dockerfile" \
    "$repoName:buildpack-deps-buster-curl"

#-------------------- Common runtime base for all runtime images --------------
buildImage \
    "$REPO_DIR/images/common/runtimeBase-stretch.Dockerfile" \
    "$repoName:runtime-stretch"

buildImage \
    "$REPO_DIR/images/common/runtimeBase-buster.Dockerfile" \
    "$repoName:runtime-buster"

#-------------------- Node ---------------------------
buildImage \
    "$REPO_DIR/images/common/nodeRuntimeBase-stretch.Dockerfile" \
    "$repoName:node-runtime-stretch"

#-------------------- .NET Core ---------------------------
buildImage \
    "$REPO_DIR/images/common/dotNetCoreRuntimeBase-stretch.Dockerfile" \
    "$repoName:dotnetcore-runtime-stretch"

buildImage \
    "$REPO_DIR/images/common/dotNetCoreRuntimeBase-buster.Dockerfile" \
    "$repoName:dotnetcore-runtime-buster"

#-------------------- PHP ---------------------------
buildImage \
    "$REPO_DIR/images/common/phpRuntimeBase-stretch.Dockerfile" \
    "$repoName:php-runtime-stretch"

echo
cat "$artifactsFile"