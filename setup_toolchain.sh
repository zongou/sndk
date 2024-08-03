#!/bin/sh
set -eu
WORKSPACE=$(dirname "$(realpath "$0")")
PROGRAM="$(basename "$0")"

# shellcheck disable=SC2059
msg() { printf "%s\n" "$*" >&2; }

get_ndk_resource() {
	ANDROID_NDK_ROOT="$1"
	TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
	NDK_SYSROOT="${TOOLCHAIN}/sysroot"
	NDK_CLANG_RESOURCE="$(find "${TOOLCHAIN}" -path "*/lib/clang/[0-9][0-9]" -type d)"

	msg "Removing old sysroot ..."
	rm -rf "${WORKSPACE}/sysroot"
	msg "Copying sysroot ..."
	cp -r "${NDK_SYSROOT}" "${WORKSPACE}/sysroot"

	msg "Removing old clang resource ..."
	rm -rf "${WORKSPACE}/resource"
	msg "Copying clang resource ..."
	cp -r "${NDK_CLANG_RESOURCE}" "${WORKSPACE}/resource"

	find "${WORKSPACE}/resource/lib" -maxdepth 1 -mindepth 1 -not -name linux -exec rm -rf {} \;
}

create_target_wrapper() {
	mkdir -p "${WORKSPACE}/bin"
	find "${WORKSPACE}/sysroot/usr/lib" -maxdepth 1 -mindepth 1 -type d | while IFS= read -r dir; do
		ANDROID_ABI=$(basename $dir)
		find "${dir}" -maxdepth 1 -mindepth 1 -type d | sort | while IFS= read -r di; do
			ANDROID_API=$(basename "$di")
			msg "link ${ANDROID_ABI}${ANDROID_API}-clang"
			ln -snf "../wrappers/target_wrapper" "${WORKSPACE}/bin/${ANDROID_ABI}${ANDROID_API}-clang"
			msg "link ${ANDROID_ABI}${ANDROID_API}-clang++"
			ln -snf "../wrappers/target_wrapper" "${WORKSPACE}/bin/${ANDROID_ABI}${ANDROID_API}-clang++"
		done
	done
}

setup() {
	get_ndk_resource "$1"
	create_target_wrapper
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
