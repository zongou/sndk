#!/bin/sh
set -eu

msg() { printf "%s$(test $# -eq 0 && cat || echo "$@")\n" >&2; }

RES_DIR="${TMPDIR}/android_dev"
mkdir -p "${RES_DIR}"

setup_jdk() {
	msg "Setting up JDK ..."
	if ! command -v java >/dev/null; then
		apt install openjdk-17 -y
	fi
	. "${PREFIX}/etc/profile.d/java.sh"

	msg "JAVA_HOME=${JAVA_HOME}"
	msg "Run: java --version:"
	java --version
}

setup_sdk() {
	msg "Setting up SDK ..."
	ANDROID_HOME=${PREFIX}/lib/android-sdk
	CMDLINETOOLS_PACKAGE=${RES_DIR}/cmdline-tools.zip
	CMDLINETOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

	mkdir -p "${ANDROID_HOME}"
	if ! test -e "${ANDROID_HOME}/tools"; then
		if ! test -e "${RES_DIR}/cmdline-tools"; then
			if ! test -e "${CMDLINETOOLS_PACKAGE}"; then
				curl -Lk "${CMDLINETOOLS_URL}" -o "${CMDLINETOOLS_PACKAGE}.tmp"
				mv "${CMDLINETOOLS_PACKAGE}.tmp" "${CMDLINETOOLS_PACKAGE}"
			fi
			(cd "${RES_DIR}" && unzip -q "${CMDLINETOOLS_PACKAGE}")
		fi
		mv "${RES_DIR}/cmdline-tools" "${ANDROID_HOME}/tools"
	fi

	SDKMANAGER="${ANDROID_HOME}/tools/bin/sdkmanager"

	## Accept licenses
	## Place cmdline-tools in $ANDROID_HOME/tools and run sdkmanager will generate package.xml if not exists
	yes | "${SDKMANAGER}" --sdk_root="${ANDROID_HOME}" --licenses >/dev/null 2>&1

	## Work around Issue: Dependant package with key emulator not found!
	sed -i 's/path=".*" obsolete/path="tools" obsolete/' "${ANDROID_HOME}/tools/package.xml"

	msg "ANDROID_HOME=${ANDROID_HOME}"
	msg "SDKMANAGER=${SDKMANAGER}"
	msg "Run: sdkmanager --version: $("${SDKMANAGER}" --sdk_root="${ANDROID_HOME}" --version)"
	msg "Run: \${SDKMANAGER} --sdk_root=\${ANDROID_HOME} --list_installed"
	"${SDKMANAGER}" --sdk_root="${ANDROID_HOME}" --list_installed
}

setup_ndk() {
	msg "Setting up NDK ..."
	NDK_VERSION=r27
	ANDROID_NDK_ROOT="${PREFIX}/lib/android-ndk-${NDK_VERSION}"
	NDK_PACKAGE="${RES_DIR}/android-ndk-${NDK_VERSION}-linux.zip"
	NDK_URL="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"

	if ! test -e "${ANDROID_NDK_ROOT}"; then
		if ! test -e "${NDK_PACKAGE}"; then
			curl -Lk "${NDK_URL}" -o "${NDK_PACKAGE}.tmp"
			mv "${NDK_PACKAGE}.tmp" "${NDK_PACKAGE}"
		fi
		(cd "$(dirname "${ANDROID_NDK_ROOT}")" && unzip -q "${NDK_PACKAGE}")
	fi

	## Fix: ERROR: Unknown host CPU architecture: aarch64
	sed -i 's/arm64)/arm64|aarch64)/' "${ANDROID_NDK_ROOT}/build/tools/ndk_bin_common.sh"

	## Replace toolchain
	TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
	CLANG_URL=https://github.com/dzbarsky/static-clang/releases/download/v18.1.2-1/linux_arm64_minimal.tar.xz
	CLANG_PACKAGE="${RES_DIR}/linux_arm64_minimal.tar.xz"
	if ! "${TOOLCHAIN}/bin/clang" --version >/dev/null 2>&1; then
		find "${TOOLCHAIN}/bin" -maxdepth 1 -mindepth 1 -not -name "*-linux-android*-clang*" -exec rm -rf {} \;
		find "${TOOLCHAIN}/lib/" -maxdepth 1 -mindepth 1 -not -name "clang" -exec rm -rf {} \;

		if ! test -e "${CLANG_PACKAGE}"; then
			(cd "${RES_DIR}" && curl -Lk "${CLANG_URL}" -o "${CLANG_PACKAGE}.tmp")
			mv "${CLANG_PACKAGE}.tmp" "${CLANG_PACKAGE}"
		fi
		xz -d <"${CLANG_PACKAGE}" | tar -C "${TOOLCHAIN}" -x bin

		## Move clang resource dir if necessarily
		CLANG_RESOURCE_DIR=$("${TOOLCHAIN}/bin/clang" --print-resource-dir)
		NDK_CLANG_RESOUCE_DIR=$(find "${TOOLCHAIN}" -path '*/lib/clang/[0-9]?')
		if ! test "${CLANG_RESOURCE_DIR}" = "${NDK_CLANG_RESOUCE_DIR}"; then
			mv "${NDK_CLANG_RESOUCE_DIR}" "${CLANG_RESOURCE_DIR}"
		fi
	fi

	## Replace python
	if ! command -v python3 >/dev/null; then
		apt install -y python3
	fi
	rm -rf "${TOOLCHAIN}/python3"
	mkdir -p "${TOOLCHAIN}/python3/bin"
	ln -snf "$(command -v python3)" "${TOOLCHAIN}/python3/bin/python3"

	## NDK also relys on command 'which' and 'make'
	for tool in which make; do
		if ! command -v "${tool}" >/dev/null; then
			apt install -y "${tool}"
		fi
	done

	msg "ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}"
	msg "TOOLCHAIN=${TOOLCHAIN}"
	msg "Run: \${TOOLCHAIN}/bin/aarch64-linux-android21-clang --version"
	"${TOOLCHAIN}/bin/aarch64-linux-android21-clang" --version
}

setup_gradle() {
	msg "Setting up gradle ..."
	if command -v apt >/dev/null && ! command -v aapt2 >/dev/null; then
		apt install -y aapt2
	fi

	mkdir -p "${HOME}/.gradle"
	GRADLE_CONFIG="${HOME}/.gradle/gradle.properties"
	cat <<EOF >"${GRADLE_CONFIG}"
android.aapt2FromMavenOverride=$(command -v aapt2)
EOF

	msg "GRADLE_CONFIG=${GRADLE_CONFIG}"
	msg "Run: cat \${GRADLE_CONFIG}"
	cat "${GRADLE_CONFIG}"
}

setup_profile() {
	msg "Setting up profile ..."
	PROFILE=${PREFIX}/etc/profile.d/android_dev.sh
	## Write env to profile
	cat <<EOF >"${PROFILE}"
export ANDROID_HOME="${ANDROID_HOME}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT}"
export SDKMANAGER="${SDKMANAGER}"
EOF

	msg "PROFILE=${PROFILE}"
	msg "Run: cat \${PROFILE}"
	cat "${PROFILE}"
}

# setup_jdk
# setup_sdk
# setup_ndk
setup_gradle
# setup_profile

# main(){
# 	while test $@ -gt 0; do
# 		eval $1
# 		shift
# 	done
# }
