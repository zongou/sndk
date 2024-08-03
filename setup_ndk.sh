#!/bin/sh
set -eu

msg() { printf "%s\n" "$*" >&2; }

TMPDIR=${TMPDIR-/tmp}

dl_cmd="curl -Lk"
if ! command -v curl >/dev/null && command -v wget >/dev/null; then
	dl_cmd="wget -O-"
fi
# ==============================================================

WORKSPACE=$(dirname $(realpath $0))
PROGRAM="$(basename "$0")"

if ! command -v clang >/dev/null; then
	msg "Cannot find clang."
	exit 1
fi

setup() {
	ANDROID_NDK_ROOT="$1"

	# msg "Setting up NDK ..."
	# NDK_VERSION=r27
	# ANDROID_NDK_ROOT="${PREFIX}/lib/android-ndk-${NDK_VERSION}"
	# NDK_PACKAGE="${RES_DIR}/android-ndk-${NDK_VERSION}-linux.zip"
	# NDK_URL="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"

	# if ! test -e "${ANDROID_NDK_ROOT}"; then
	# 	if ! test -e "${NDK_PACKAGE}"; then
	# 		curl -Lk "${NDK_URL}" -o "${NDK_PACKAGE}.tmp"
	# 		mv "${NDK_PACKAGE}.tmp" "${NDK_PACKAGE}"
	# 	fi
	# 	(cd "$(dirname "${ANDROID_NDK_ROOT}")" && unzip -q "${NDK_PACKAGE}")
	# fi

	## Fix: ERROR: Unknown host CPU architecture: aarch64
	sed -i 's/arm64)/arm64|aarch64)/' "${ANDROID_NDK_ROOT}/build/tools/ndk_bin_common.sh"

	# ## Replace toolchain
	TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
	# CLANG_URL=https://github.com/dzbarsky/static-clang/releases/download/v18.1.2-1/linux_arm64_minimal.tar.xz
	# CLANG_PACKAGE="${RES_DIR}/linux_arm64_minimal.tar.xz"
	# if ! "${TOOLCHAIN}/bin/clang" --version >/dev/null 2>&1; then
	# 	find "${TOOLCHAIN}/bin" -maxdepth 1 -mindepth 1 -not -name "*-linux-android*-clang*" -exec rm -rf {} \;
	# 	find "${TOOLCHAIN}/lib/" -maxdepth 1 -mindepth 1 -not -name "clang" -exec rm -rf {} \;

	# 	if ! test -e "${CLANG_PACKAGE}"; then
	# 		(cd "${RES_DIR}" && curl -Lk "${CLANG_URL}" -o "${CLANG_PACKAGE}.tmp")
	# 		mv "${CLANG_PACKAGE}.tmp" "${CLANG_PACKAGE}"
	# 	fi
	# 	xz -d <"${CLANG_PACKAGE}" | tar -C "${TOOLCHAIN}" -x bin

	# 	## Move clang resource dir if necessarily
	# 	CLANG_RESOURCE_DIR=$("${TOOLCHAIN}/bin/clang" --print-resource-dir)
	# 	NDK_CLANG_RESOUCE_DIR=$(find "${TOOLCHAIN}" -path '*/lib/clang/[0-9]?')
	# 	if ! test "${CLANG_RESOURCE_DIR}" = "${NDK_CLANG_RESOUCE_DIR}"; then
	# 		mv "${NDK_CLANG_RESOUCE_DIR}" "${CLANG_RESOURCE_DIR}"
	# 	fi
	# fi

	## Replace python
	if command -v python3 >/dev/null; then
		rm -rf "${TOOLCHAIN}/python3"
		mkdir -p "${TOOLCHAIN}/python3/bin"
		ln -snf "$(command -v python3)" "${TOOLCHAIN}/python3/bin/python3"
	else
		msg "Warming: Cannot find 'python3'"
		cat <<-EOF >"${TOOLCHAIN}/python3/bin/python3"
			printf "Called python with args: '%s'\nIn dir: %s\n" "\$*" "\${PWD}" >&2
		EOF
		chmod +x "${TOOLCHAIN}/python3/bin/python3"
	fi

	## NDK requires tool 'which' and 'make'
	for tool in which make; do
		if ! command -v "${tool}" >/dev/null; then
			msg "Cannot find '${tool}'"
			exit 1
		fi
	done

	## Create target wrapper
	rm -rf "${TOOLCHAIN}/bin" && mkdir "${TOOLCHAIN}/bin"
	cp "${WORKSPACE}/wrappers/target_wrapper" "${TOOLCHAIN}/bin/clang"
	NDK_CLANG_RESOURCE="$(find "${TOOLCHAIN}/lib/clang" -path "*/[0-9][0-9]" -type d -exec realpath {} \;)"
	sed -i "s^RESOURCE_DIR=.*^RESOURCE_DIR=${NDK_CLANG_RESOURCE}^" "${TOOLCHAIN}/bin/clang"
	ln -snf "clang" "${TOOLCHAIN}/bin/clang++"

	if ${CLANG-clang} -v 2>&1 | grep -q alpine; then
		cp "${WORKSPACE}/wrappers/alpine/ld.lld" "${TOOLCHAIN}/bin/ld.lld"
	fi

	find "${TOOLCHAIN}/sysroot/usr/lib" -maxdepth 1 -mindepth 1 -type d | while IFS= read -r dir; do
		ANDROID_ABI=$(basename $dir)
		find "${dir}" -maxdepth 1 -mindepth 1 -type d | sort | while IFS= read -r di; do
			ANDROID_API=$(basename "$di")
			msg "link ${ANDROID_ABI}${ANDROID_API}-clang"
			ln -snf "clang" "${TOOLCHAIN}/bin/${ANDROID_ABI}${ANDROID_API}-clang"
			msg "link ${ANDROID_ABI}${ANDROID_API}-clang++"
			ln -snf "clang" "${TOOLCHAIN}/bin/${ANDROID_ABI}${ANDROID_API}-clang++"
		done
	done

	## Link llvm-wrapper
	find "/usr/bin" -name "llvm-*" | while IFS= read -r f; do
		echo link "$(basename $f)"
		ln -snf "$f" "${TOOLCHAIN}/bin/$(basename $f)"
	done

	## Remove unused resource
	rm -rf "${TOOLCHAIN}/musl"
	find "${TOOLCHAIN}/lib" -maxdepth 1 -mindepth 1 -not -name clang -exec rm -rf {} \;
	find "${TOOLCHAIN}" -maxdepth 5 -path "*/lib/clang/[0-9][0-9]/lib/*" -not -name linux -exec rm -rf {} \;
}

show_help() {
	printf "Usage: %s <ANDROID_NDK_ROOT>\n" "${PROGRAM}"
}

main() {
	if test $# -eq 1; then
		setup "$1"
	else
		show_help
	fi
}

main "$@"
