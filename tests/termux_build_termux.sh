#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(dirname $(realpath $0)))
. ${ROOT_DIR}/config.sh
. ${PREFIX}/etc/profile.d/android_build.sh

## Setup Android build enviroment
${ROOT_DIR}/tests/termux_setup_android_build_enviroment.sh

## Clone termux
if ! test -d termux-app; then
    if ! test -d termux-app; then
        # GHPROXY=https://ghproxy.net/
        git clone ${GHPROXY-}https://github.com/zongou/termux-app --depth=1
    fi
fi

cd termux-app
git clean -xdf

# sdk.dir=${ANDROID_HOME}
rm -f local.properties
cat <<EOF >local.properties
ndk.dir=${ANDROID_NDK_ROOT}
EOF

${GRADLE} assembleRelease
