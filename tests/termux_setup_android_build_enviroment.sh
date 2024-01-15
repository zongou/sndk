#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(dirname $(realpath $0)))
. ${ROOT_DIR}/config.sh

## Setup JDK
if ! command -v java >/dev/null; then
    pkg install -y openjdk-17
fi

## Setup gradle
if ! test -d $PREFIX/opt/gradle-8.10.2; then
    pkg install -y aapt2
    ${ROOT_DIR}/setup_gradle.sh ${PREFIX}/opt
fi

# ## Setup SDK
if ! test -d $PREFIX/opt/android-sdk; then
    ${ROOT_DIR}/setup_sdk.sh ${PREFIX}/opt
fi

## Setup NDK
if ! test -d ${PREFIX}/opt/android-ndk-${NDK_VERSION}; then
    pkg install -y clang which make
    if ! test -d ${PREFIX}/opt/android-ndk-${NDK_VERSION}; then
        if ! test -f ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip; then
            ndk_url=https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip
            ${dl_cmd} ${ndk_url} >${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip.tmp
            mv ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip.tmp ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip
        fi
        unzip -d ${PREFIX}/opt ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip
    fi
    ${ROOT_DIR}/setup_ndk.sh ${PREFIX}/opt/android-ndk-${NDK_VERSION}
fi

cat <<-EOF >${PREFIX}/etc/profile.d/android_build.sh
export GRADLE=${PREFIX}/opt/gradle-${GRADLE_VERSION}/bin/gradle
export ANDROID_HOME=${PREFIX}/opt/android-sdk
export ANDROID_NDK_ROOT=${PREFIX}/opt/android-ndk-${NDK_VERSION}
EOF
