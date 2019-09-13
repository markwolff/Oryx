#!/bin/bash

fileExtension=".tar.gz"
platformName=""
version=""
getPlatformNameAndVersion() {
    local fileName="$1"
    fileNameWithoutExtension=$(echo "$fileName" | sed "s/$extension//g")
    IFS='-' read -ra nameAndVersion <<< "$fileNameWithoutExtension"
    if [ "${#nameAndVersion[@]}" -eq 2 ]; then
        platformName="${nameAndVersion[0]}"
        version="${nameAndVersion[1]}"
    fi
}

sdkDir="$(System.ArtifactsDirectory)/drop/platformSdks"

for file in "$sdkDir/*"
do
    if [[ "$file" == *$fileExtension ]]; then
        getPlatformNameAndVersion "$file"
    fi
done

