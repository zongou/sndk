#!/bin/sh
set -eu

msg() { printf "%s\n" "$*" >&2; }

TMPDIR=${TMPDIR-/tmp}

dl_cmd="curl -Lk"
if ! command -v curl >/dev/null && command -v wget >/dev/null; then
	dl_cmd="wget -O-"
fi
# ==============================================================

if ! command -v java >/dev/null; then
	msg "java not found"
	exit 1
else
	## In termux, Source java profile.
	if test "${PREFIX+1}"; then
		if test -f ${PREFIX}/etc/profile.d/java.sh; then
			. ${PREFIX}/etc/profile.d/java.sh
		fi
	fi
fi

ANDROID_SDK_ROOT=${PREFIX-}/opt/android-sdk

if ! command -v java >/dev/null; then
	msg "java not found"
	exit 1
fi

setup_sdk() {
	msg "Setting up SDK ..."
	CMDLINETOOLS_PACKAGE=${TMPDIR}/cmdline-tools.zip
	CMDLINETOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

	mkdir -p "${ANDROID_SDK_ROOT}"
	if ! test -e "${ANDROID_SDK_ROOT}/tools"; then
		if ! test -e "${TMPDIR}/cmdline-tools"; then
			if ! test -e "${CMDLINETOOLS_PACKAGE}"; then
				${dl_cmd} "${CMDLINETOOLS_URL}" >"${CMDLINETOOLS_PACKAGE}.tmp"
				mv "${CMDLINETOOLS_PACKAGE}.tmp" "${CMDLINETOOLS_PACKAGE}"
			fi
			(cd "${TMPDIR}" && unzip -q "${CMDLINETOOLS_PACKAGE}")
		fi
		mv "${TMPDIR}/cmdline-tools" "${ANDROID_SDK_ROOT}/tools"
	fi

	SDKMANAGER="${ANDROID_SDK_ROOT}/tools/bin/sdkmanager"

	## Accept licenses
	## Place cmdline-tools in $ANDROID_SDK_ROOT/tools and run sdkmanager will generate package.xml if not exists
	yes | "${SDKMANAGER}" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >/dev/null 2>&1

	## Work around Issue: Dependant package with key emulator not found!
	sed -i 's/path=".*" obsolete/path="tools" obsolete/' "${ANDROID_SDK_ROOT}/tools/package.xml"

	msg "sdkmanager list installed packages:"
	"${SDKMANAGER}" --sdk_root="${ANDROID_SDK_ROOT}" --list_installed
}

# setup_profile() {
# 	cat <<-EOF >/etc/profile.d/sndk.sh
# 		export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"
# 		export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
# 	EOF
# }

setup_sdk
# setup_profile
