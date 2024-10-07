#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(dirname $(realpath $0)))
. ${ROOT_DIR}/config.sh
. ${PREFIX-}/etc/profile.d/android_build.sh

## Clone termux
if ! test -d termux-app; then
    if ! test -d termux-app; then
        # GHPROXY=https://ghproxy.net/
        git clone ${GHPROXY-}https://github.com/zongou/termux-app --depth=1
    fi
fi

cd termux-app
# sdk.dir=${ANDROID_HOME}
rm -f local.properties
cat <<EOF >local.properties
ndk.dir=${ANDROID_NDK_ROOT}
android.aapt2FromMavenOverride="/usr/local/bin/aapt2"
EOF

# ${GRADLE} assembleRelease --info
${GRADLE} assembleDebug
