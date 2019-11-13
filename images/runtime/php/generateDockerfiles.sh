#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd ../../.. && pwd )
declare -r DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source "$DIR/__versions.sh"
source "$REPO_DIR/build/__baseImageTags.sh"

declare -r DOCKERFILE_TEMPLATE="$DIR/Dockerfile.template"
declare -r DOCKERFILE_BASE_TEMPLATE="$DIR/Dockerfile.base.template"
declare -r IMAGE_NAME_PLACEHOLDER="%PHP_BASE_IMAGE%"
declare -r PHP_VERSION_PLACEHOLDER="%PHP_VERSION%"

for PHP_VERSION in "${VERSION_ARRAY[@]}"
do
	IFS='.' read -ra SPLIT_VERSION <<< "$PHP_VERSION"
	VERSION_DIRECTORY="${SPLIT_VERSION[0]}.${SPLIT_VERSION[1]}"

	PHP_IMAGE_NAME="php-$VERSION_DIRECTORY"
	echo "Generating Dockerfile for image '$PHP_IMAGE_NAME' in directory '$VERSION_DIRECTORY'..."

	mkdir -p "$DIR/$VERSION_DIRECTORY/"
	TARGET_DOCKERFILE="$DIR/$VERSION_DIRECTORY/Dockerfile"
	TARGET_DOCKERFILE_BASE="$DIR/$VERSION_DIRECTORY/Dockerfile.base"
	cp "$DOCKERFILE_TEMPLATE" "$TARGET_DOCKERFILE"
	cp "$DOCKERFILE_BASE_TEMPLATE" "$TARGET_DOCKERFILE_BASE"

	sed -i "s|%PHP_BASE_IMAGE%|$PHP_IMAGE_NAME|g" "$TARGET_DOCKERFILE_BASE"

	RUNTIME_BASE_IMAGE_NAME="mcr.microsoft.com/oryx/base:php-$VERSION_DIRECTORY-$PHP_RUNTIME_BASE_TAG"
	sed -i "s|%RUNTIME_BASE_IMAGE_NAME%|$RUNTIME_BASE_IMAGE_NAME|g" "$TARGET_DOCKERFILE"
done
