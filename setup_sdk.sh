#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(realpath $0))
. ${ROOT_DIR}/config.sh

setup() {
	PREFIX_DIR="$1"

	msg "Setting up SDK ..."
	check_tools java
	ANDROID_SDK_ROOT=${PREFIX_DIR}/android-sdk
	CMDLINETOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINETOOLS_VERSION}_latest.zip"
	SDKMANAGER="${ANDROID_SDK_ROOT}/tools/bin/sdkmanager"

	if ! test -d "${ANDROID_SDK_ROOT}/tools"; then
		mkdir -p "${ANDROID_SDK_ROOT}"
		CMDLINETOOLS_PACKAGE="${TMPDIR}/cmdline-tools.zip"
		if ! test -f "${CMDLINETOOLS_PACKAGE}"; then
			$dl_cmd "${CMDLINETOOLS_URL}" >"${CMDLINETOOLS_PACKAGE}.tmp"
			mv "${CMDLINETOOLS_PACKAGE}.tmp" "${CMDLINETOOLS_PACKAGE}"
		fi
		
		unzip -q -d "$TMPDIR" "${CMDLINETOOLS_PACKAGE}"
		mv "${TMPDIR}/cmdline-tools" "${ANDROID_SDK_ROOT}/tools"

		## Accept licenses
		## Place cmdline-tools in $ANDROID_SDK_ROOT/tools and run sdkmanager will generate package.xml if not exists
		yes | "${SDKMANAGER}" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >/dev/null 2>&1

		## Work around Issue: Dependant package with key emulator not found!
		sed -i 's/path=".*" obsolete/path="tools" obsolete/' "${ANDROID_SDK_ROOT}/tools/package.xml"
	fi

	msg "Checking SDK ..."
	"${SDKMANAGER}" --sdk_root="${ANDROID_SDK_ROOT}" --list_installed
}

if test $# -gt 0; then
	setup "$1"
else
	msg "Usage: ${PROGRAM} [PREFIX_DIR]"
fi
