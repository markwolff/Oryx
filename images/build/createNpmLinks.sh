#!/bin/bash

set -ex

for ver in `ls /opt/node`
do
    npm_ver=`jq -r .version /opt/node/$ver/lib/node_modules/npm/package.json`
    if [ ! -d /opt/npm/$npm_ver ]; then
        mkdir -p /opt/npm/$npm_ver
        ln -s /opt/node/$ver/lib/node_modules /opt/npm/$npm_ver/node_modules
        ln -s /opt/node/$ver/lib/node_modules/npm/bin/npm /opt/npm/$npm_ver/npm
        if [ -e /opt/node/$ver/lib/node_modules/npm/bin/npx ]; then
            chmod +x /opt/node/$ver/lib/node_modules/npm/bin/npx
            ln -s /opt/node/$ver/lib/node_modules/npm/bin/npx /opt/npm/$npm_ver/npx
        fi
    fi
done
