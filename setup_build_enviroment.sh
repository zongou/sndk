#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(realpath $0))
. ${ROOT_DIR}/config.sh
PREFIX=${PREFIX-}
INSTALL_PREFIX=${PREFIX}/opt

# SDK
${ROOT_DIR}/setup_sdk.sh "${INSTALL_PREFIX}"

# Gradle
${ROOT_DIR}/setup_gradle.sh ${INSTALL_PREFIX}

# NDK
if ! test -d ${INSTALL_PREFIX}/android-ndk-${NDK_VERSION}; then
    if ! test -f ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip; then
        ndk_url=https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip
        ${dl_cmd} ${ndk_url} >${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip.tmp
        mv ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip.tmp ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip
    fi
    unzip -d ${INSTALL_PREFIX} ${TMPDIR}/android-ndk-${NDK_VERSION}-linux.zip
fi
${ROOT_DIR}/setup_ndk.sh ${INSTALL_PREFIX}/android-ndk-${NDK_VERSION}

# Profile
cat <<-EOF >${PREFIX}/etc/profile.d/android_build.sh
export GRADLE=${INSTALL_PREFIX}/gradle-${GRADLE_VERSION}/bin/gradle
export ANDROID_HOME=${INSTALL_PREFIX}/android-sdk
export ANDROID_NDK_ROOT=${INSTALL_PREFIX}/android-ndk-${NDK_VERSION}
EOF

check_tools aapt2
aapt2 version
mkdir -p "${HOME}/.gradle"
GRADLE_CONFIG="${HOME}/.gradle/gradle.properties"
cat <<EOF >"${GRADLE_CONFIG}"
android.aapt2FromMavenOverride=$(command -v aapt2)
EOF
cat "${GRADLE_CONFIG}"

cat ${PREFIX}/etc/profile.d/android_build.sh
