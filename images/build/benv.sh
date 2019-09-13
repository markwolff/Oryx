#!/bin/bash
# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT license.
# --------------------------------------------------------------------------------------------

# Perform case-insensitive comparison
benv-matchesName() {
  local expectedName="$1"
  local providedName="$2"
  local result=
  shopt -s nocasematch
  [[ "$expectedName" == "$providedName" ]] && result=0 || result=1
  shopt -u nocasematch
   return $result
}

# Read the environment variables to see if a value for these variables have been set.
# If a variable was set as an environment variable AND as an argument to benv script, then the argument wins.
# Example:
#   export dotnet=1
#   source benv dotnet=3
#   dotnet --version (This should print version 3)
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^php=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^php_version=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^python=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^python_version=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^node=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^node_version=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^npm=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^npm_version=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^dotnet=')
while read benvvar; do
  set -- "$benvvar" "$@"
done < <(set | grep -i '^dotnet_version=')
unset benvvar # Remove all traces of this part of the script

ORYX_BLOB_URL_BASE="https://oryxsdks.blob.core.windows.net/sdks"

benv-getFullVersion() {
  local platformName="$1"
  local version="$2"
  IFS='.' read -ra VERSION_PARTS <<< "$version"
  local partsLength="${#VERSION_PARTS[@]}"
  if [ $partsLength -eq 1 ]; then
    local lookupVersion="${VERSION_PARTS[0]}"
  elif [ $partsLength -eq 2 ]; then
    local lookupVersion="${VERSION_PARTS[0]}.${VERSION_PARTS[1]}"
  else [ $partsLength -eq 3 ]
    echo "$version"
    return 0
  fi
  
  local blobName="$platformName-$lookupVersion.tar.gz"
  local lookupText="x-ms-meta-fullVersion: "
  version=$(curl -I $ORYX_BLOB_URL_BASE/$blobName 2> /dev/null | grep -Fi $lookupText | sed -e "s/$lookupText//g" | tr -d '\r')
  echo "$version"
}

benv-downloadSdkAndExtract() {
    local platformName="$1"
    local version="$2"
    local blobName="$platformName-$version.tar.gz"
    
    currentDir=`pwd`
    platformDir="/tmp/oryx/$platformName"
    targetDir="$platformDir/$version"
    if [ -d "$targetDir" ]; then
      echo "$platformName version '$version' already exists. Skipping installing it..."
    else
      curl -I $ORYX_BLOB_URL_BASE/$blobName 2> /tmp/curlError.txt 1> /tmp/curlOut.txt
      grep "HTTP/1.1 200 OK" /tmp/curlOut.txt &> /dev/null
      exitCode=$?
      rm -f /tmp/curlError.txt
      rm -f /tmp/curlOut.txt
      if [ ! $exitCode -eq 0 ]; then
        echo "Could not find version '$version' of '$platformName' in Oryx blob storage."
        exit 1
      fi

      echo "Downloading and extracing version '$version' of platform '$platformName'..."
      cd /tmp
      curl -SL $ORYX_BLOB_URL_BASE/$platformName-$version.tar.gz --output $platformName-$version.tar.gz &> /dev/null
      mkdir -p "$targetDir"
      tar -xzf $platformName-$version.tar.gz -C "$targetDir"

      # Create a link : major.minor => major.minor.patch
      cd "$platformDir"
      IFS='.' read -ra VERSION_PARTS <<< "$version"
      MAJOR_MINOR="${SDK_VERSION_PARTS[0]}.${SDK_VERSION_PARTS[1]}"
      echo "Creating link from $MAJOR_MINOR to $version..."
      ln -s $version $MAJOR_MINOR
    fi

    cd "$currentDir"
}

benv-getStringIndex() {
  local lookUpText="$1"
  local actualString="$2"

  # Find the string 'before' the text we are looking for
  # and if found get the length of it which will give index
  # of the lookup text
  result="${actualString%%$lookUpText*}"
  if [ "$result" == "$actualString" ]; then
    echo -1 
  else
    echo "${#result}"
  fi
}

# Oryx's paths come to the end of the PATH environment variable so that any user installed platform
# sdk versions can be picked up. Here we are trying to find the first occurrence of a path like '/opt/'
# (as in /opt/dotnet) and inserting a more specific provided path before it.
# Example: (note that all Oryx related patlform paths come in the end)
# /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/node/6/bin:/opt/dotnet/2.2.401:/opt/oryx/defaultversions
benv-benv-updatePath() {
  local pathToBeInserted="$1"
  local currentPath="$PATH"
  local builtInInstallDirPrefix="/opt/"
  local dynamicInstallDirPrefix="/tmp/oryx/"
  local builtInInstallDirIndex=$(benv-getStringIndex $builtInInstallDirPrefix "$currentPath")
  local dynamicInstallDirIndex=$(benv-getStringIndex $dynamicInstallDirPrefix "$currentPath")

  if [ $dynamicInstallDirIndex -ne -1 ] && [ $dynamicInstallDirIndex -lt $builtInInstallDirIndex ]; then
    local replacingText="$pathToBeInserted:$dynamicInstallDirPrefix"
    local lookUpText="\/tmp\/oryx\/"
  else
    local replacingText="$pathToBeInserted:$builtInInstallDirPrefix"
    local lookUpText="\/opt\/"
  fi

  local newPath=$(echo $currentPath | sed "0,/$lookUpText/ s##$replacingText#")
  export PATH="$newPath"
}

benv-versions() {
  local IFS=$' \r\n'
  local version
  for version in $(ls "$1"); do
    local link=$(readlink "$1/$version" || echo -n)
    if [ -z "$link" ]; then
      echo "  $version"
    else
      echo "  $version -> $link"
    fi
  done
}

benv-getPlatformDir() {
  local platformDirName="$1"
  local userSuppliedVersion="$2"
  local builtInInstallDir="/opt/$platformDirName"
  local dynamicInstallDir="/tmp/oryx/$platformDirName"

  if [ -d "$builtInInstallDir/$userSuppliedVersion" ]; then
    echo "$builtInInstallDir/$userSuppliedVersion"
  elif [ -d "$dynamicInstallDir/$userSuppliedVersion" ]; then
    echo "$dynamicInstallDir/$userSuppliedVersion"
  else
    echo "NotFound"
  fi
}

benv-showSupportedVersionsErrorInfo() {
  local userPlatformName="$1"
  local platformDirName="$2"
  local userSuppliedVersion="$3"
  local builtInInstallDir="/opt/$platformDirName"
  local dynamicInstallDir="/tmp/oryx/$platformDirName"

  echo >&2 benv: "$userPlatformName" version \'$userSuppliedVersion\' not found\; choose one of:
  benv-versions >&2 "$builtInInstallDir"

  if [ -d "$dynamicInstallDir" ]; then
    benv-versions >&2 "$dynamicInstallDir"
  fi
}

benv-resolve() {
  local name=$(echo $1 | sed 's/=.*$//')
  local value=$(echo $1 | sed 's/^.*=//')
  local dynamicInstallRootDir="/tmp/oryx"

  # Resolve node versions
  if benv-matchesName "node" "$name" || benv-matchesName "node_version" "$name" && [ "${value::1}" != "/" ]; then
    platformDir=$(benv-getPlatformDir "node" "$value")
    if [ "$platformDir" == "NotFound" ]; then
      if [ "$ORYX_ENABLE_DYNAMIC_TOOL_INSTALLATION" == "true" ]; then
        benv-downloadSdkAndExtract "node" "$value"
      else
        benv-showSupportedVersionsErrorInfo "node" "node" "$value"
        return 1
      fi
    fi 

    local DIR="$platformDir/$value/bin"
    benv-benv-updatePath "$DIR"
    export node="$DIR/node"
    export npm="$DIR/npm"
    if [ -e "$DIR/npx" ]; then
      export npx="$DIR/npx"
    fi

    return 0
  fi

  # Resolve npm versions
  if benv-matchesName "npm" "$name" || benv-matchesName "npm_version" "$name" && [ "${value::1}" != "/" ]; then
    platformDir=$(benv-getPlatformDir "npm" "$value")
    if [ "$platformDir" == "NotFound" ]; then
      if [ "$ORYX_ENABLE_DYNAMIC_TOOL_INSTALLATION" == "true" ]; then
        benv-downloadSdkAndExtract "npm" "$value"
      else
        benv-showSupportedVersionsErrorInfo "npm" "npm" "$value"
        return 1
      fi
    fi

    local DIR="$platformDir/$value"
    benv-benv-updatePath "$DIR"
    export npm="$DIR/npm"
    if [ -e "$DIR/npx" ]; then
      export npx="$DIR/npx"
    fi

    return 0
  fi

  # Resolve python versions
  if benv-matchesName "python" "$name" || benv-matchesName "python_version" "$name" && [ "${value::1}" != "/" ]; then
    platformDir=$(benv-getPlatformDir "python" "$value")
    if [ "$platformDir" == "NotFound" ]; then
      if [ "$ORYX_ENABLE_DYNAMIC_TOOL_INSTALLATION" == "true" ]; then
        value=$(benv-getFullVersion "python" "$value")
        benv-downloadSdkAndExtract "python" "$value"
        export LD_LIBRARY_PATH="$dynamicInstallRootDir/python/$value/lib:$LD_LIBRARY_PATH"
      else
        benv-showSupportedVersionsErrorInfo "python" "python" "$value"
        return 1
      fi
    fi 

    local DIR="$platformDir/$value/bin"
    benv-benv-updatePath "$DIR"
    if [ -e "$DIR/python2" ]; then
      export python="$DIR/python2"
    elif [ -e "$DIR/python3" ]; then
      export python="$DIR/python3"
    fi
    export pip="$DIR/pip"
    if [ -e "$DIR/virtualenv" ]; then
      export virtualenv="$DIR/virtualenv"
    fi

    return 0
  fi

  # Resolve PHP versions
  if benv-matchesName "php" "$name" || benv-matchesName "php_version" "$name" && [ "${value::1}" != "/" ]; then
    platformDir=$(benv-getPlatformDir "php" "$value")
    if [ "$platformDir" == "NotFound" ];then
      if [ "$ORYX_ENABLE_DYNAMIC_TOOL_INSTALLATION" == "true" ]; then
        benv-downloadSdkAndExtract "php" "$value"
        export LD_LIBRARY_PATH="$dynamicInstallRootDir/php/$value/lib:$LD_LIBRARY_PATH"
      else
        benv-showSupportedVersionsErrorInfo "php" "php" "$value"
        return 1
      fi
    fi

    local DIR="$platformDir/$value/bin"
    benv-benv-updatePath "$DIR"
    export php="$DIR/php"

    return 0
  fi

  if benv-matchesName "composer" "$name" || benv-matchesName "composer_version" "$name" && [ "${value::1}" != "/" ]; then
    platformDir=$(benv-getPlatformDir "php-composer" "$value")
    if [ "$platformDir" == "NotFound" ]; then
      if [ "$ORYX_ENABLE_DYNAMIC_TOOL_INSTALLATION" == "true" ]; then
        benv-downloadSdkAndExtract "php-composer" "$value"
      else
        benv-showSupportedVersionsErrorInfo "composer" "php-composer" "$value"
        return 1
      fi
    fi

    local DIR="$platformDir/$value"
    benv-benv-updatePath "$DIR"
    export composer="$DIR/composer.phar"

    return 0
  fi

  # Resolve dotnet versions
  if benv-matchesName "dotnet" "$name" || benv-matchesName "dotnet_version" "$name" && [ "${value::1}" != "/" ]; then
    local runtimesDir="/opt/dotnet/runtimes"
    if [ ! -d "$runtimesDir/$value" ]; then
      echo >&2 benv: dotnet version \'$value\' not found\; choose one of:
      benv-versions >&2 $runtimesDir
      return 1
    fi

    local DIR=$(readlink $"$runtimesDir/$value/sdk")
    benv-benv-updatePath "$DIR"
    export dotnet="$DIR/dotnet"
    
    return 0
  fi

  # Export other names without resolution
  eval export $name\=\'${value//\'/\'\\\'\'}\'
}

# Iterate through arguments of the format "name=value"
# and resolve each one, or exit if there is a failure.
while [[ $1 = *"="* ]]; do
  benv-resolve "$1" || if [ "$0" != "$BASH_SOURCE" ]; then
    # Remove all traces of this script prior to returning
    unset -f benv-resolve benv-versions;
    return 1;
  else
    exit 1;
  fi
  shift
done

if [ "$0" != "$BASH_SOURCE" ]; then
  # Remove all traces of this script prior to returning
  unset -f benv-resolve benv-versions
  if [ $# -gt 0 ]; then
    source "$@"
  fi
else
  if [ $# -eq 0 ]; then
    if [ $$ -eq 1 ]; then
      set -- bash
    else
      set -- env
    fi
  fi
  exec "$@"
fi