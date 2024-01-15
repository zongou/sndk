#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(dirname $(realpath $0)))
. ${ROOT_DIR}/config.sh
. ${PREFIX-}/etc/profile.d/android_build.sh

## Clone termux
if ! test -d termux-app; then
    if ! test -d termux-app; then
        GHPROXY=https://ghproxy.net/
        git clone ${GHPROXY-}https://github.com/zongou/termux-app --depth=1
    fi
fi

cd termux-app
git clean -xdf

## Gradle properties files
## https://developer.android.google.cn/build?hl=en#properties-files
rm -f local.properties
cat <<-EOF >local.properties
# sdk.dir=${ANDROID_HOME}
ndk.dir=${ANDROID_NDK_ROOT}
EOF

${GRADLE} assembleRelease "$@"
