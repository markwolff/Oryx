#!/bin/bash
set -ex

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd ../../.. && pwd )
declare -r CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

source "$CURRENT_DIR/__versions.sh"
source "$REPO_DIR/build/__baseImageTags.sh"

for PHP_VERSION in "${VERSION_ARRAY[@]}"
do
	IFS='.' read -ra SPLIT_VERSION <<< "$PHP_VERSION"
	VERSION_DIRECTORY="${SPLIT_VERSION[0]}.${SPLIT_VERSION[1]}"

	PHP_IMAGE_NAME="php-$VERSION_DIRECTORY"
    cd "$CURRENT_DIR/$VERSION_DIRECTORY/"

    dockerFile="Dockerfile.$VERSION_DIRECTORY"
	sed -i "s|%BASE_TAG%|$PHP_RUNTIME_BASE_TAG|g" "$dockerFile"

    echo
    echo "Building php image '$PHP_IMAGE_NAME'..."
    echo
	docker build \
        -t $PHP_IMAGE_NAME \
        -f "$dockerFile" \
        --build-arg PHP_RUNTIME_BASE_TAG="-$PHP_RUNTIME_BASE_TAG" \
        .
done