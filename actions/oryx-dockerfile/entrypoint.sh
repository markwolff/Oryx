#!/bin/sh -l

sourceDirectory=$1
dockerfilePath=$2
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

oryxCommand="oryx dockerfile ${sourceDirectory}"

echo

if [ -n "${dockerfilePath}" ]
then
    echo "Output Dockerfile provided -- the generated Dockerfile will be written to the following file: '${dockerfilePath}'"
else
    dockerfilePath="${sourceDirectory}/Dockerfile.oryx"
    echo "No output Dockerfile provided -- the generated Dockerfile will be written to the following file: '${dockerfilePath}'"
fi

oryxCommand="${oryxCommand} --output ${dockerfilePath}"

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

echo ::set-output name=dockerfile-path::$dockerfilePath