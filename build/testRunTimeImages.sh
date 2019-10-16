#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

set -e

declare -r REPO_DIR=$( cd $( dirname "$0" ) && cd .. && pwd )
declare -r buildRuntimeImagesScript="$REPO_DIR/build/buildRunTimeImages.sh"
declare -r testProjectName="Oryx.RuntimeImage.Tests"

# Load all variables
source $REPO_DIR/build/__variables.sh

if [ "$1" = "skipBuildingImages" ]
then
    echo
    echo "Skipping building runtime images as argument '$1' was passed..."
else
    echo
    echo "Invoking script '$buildRuntimeImagesScript'..."
    $buildRuntimeImagesScript "$@"
fi

echo
echo "Building and running tests..."
cd "$TESTS_SRC_DIR/$testProjectName"

artifactsDir="$REPO_DIR/artifacts"
mkdir -p "$artifactsDir"

# Create a directory to capture any debug logs that MSBuild generates
msbuildDebugLogsDir="$artifactsDir/msbuildDebugLogs"
mkdir -p "$msbuildDebugLogsDir"
export MSBUILDDEBUGPATH="$msbuildDebugLogsDir"
export COMPlus_DbgEnableMiniDump="1"
export COMPlus_DbgMiniDumpName="$ARTIFACTS_DIR/$testProjectName-dump.%d"

diagnosticFileLocation="$artifactsDir/$testProjectName-log.txt"
dotnet test \
    --blame \
    --diag "$diagnosticFileLocation" \
    --test-adapter-path:. \
    --logger:"xunit;LogFilePath=$ARTIFACTS_DIR\testResults\\$testProjectName.xml" \
    -c $BUILD_CONFIGURATION

# --blame flag generates an xml file which it drops under the project directory.
# Copy that file to artifacts directory too
if [ -d "TestResults" ]; then
    resultsDir="$ARTIFACTS_DIR/$testProjectName.TestResults"
    mkdir -p "$resultsDir"
    cp -rf TestResults/. "$resultsDir/"
fi