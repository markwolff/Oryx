#!/bin/sh -l

sourceDirectory=$1
outputDirectory=$2
platform=$3
platformVersion=$4

echo

if [ -n "${sourceDirectory}" ]
then
    sourceDirectory="$PWD/$sourceDirectory"
    echo "Relative path to source directory provided -- the following directory will be built: '${sourceDirectory}'"
else
    sourceDirectory=$PWD
    echo "No source directory provided -- the root of the repository ('GITHUB_WORKSPACE' environment variable) will be built: '${sourceDirectory}'"
fi

echo
oryxCommand="oryx build ${sourceDirectory}"

if [ -n "${outputDirectory}" ]
then
    oryxCommand="${oryxCommand} --output ${outputDirectory}"
    echo "Output directory provided -- the build artifacts will be written to the following directory: '${outputDirectory}'"
else
    echo "No output directory provided -- the given platform will determine where the build artifacts are placed within the repository."
fi

echo

if [ -n "${platform}" ]
then
    echo "Platform provided: '${platform}'"
    oryxCommand="${oryxCommand} --platform ${platform}"
else
    echo "No platform provided -- Oryx will enumerate the source directory to determine the platform."
fi

echo

if [ -n "${platformVersion}" ]
then
    echo "Platform version provided: '${platformVersion}'"
    oryxCommand="${oryxCommand} --platform-version ${platformVersion}"
else
    echo "No platform version provided -- Oryx will determine the version."
fi

echo
echo "Running command '${oryxCommand}'"
eval $oryxCommand