#!/bin/sh
set -eu

ROOT_DIR=$(dirname "$(realpath "$0")")
PROGRAM="$(basename "$0")"

# shellcheck disable=SC2059
msg() { printf "%s\n" "$*" >&2; }

setup() {
	## Get ndk resource
	ANDROID_NDK_ROOT="$1"
	TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
	NDK_SYSROOT="${TOOLCHAIN}/sysroot"
	NDK_CLANG_RESOURCE="$(find "${TOOLCHAIN}" -path "*/lib/clang/[0-9][0-9]" -type d)"

	msg "Removing old sysroot ..."
	rm -rf "${ROOT_DIR}/sysroot"
	msg "Copying sysroot ..."
	cp -r "${NDK_SYSROOT}" "${ROOT_DIR}/sysroot"

	msg "Removing old clang resource ..."
	rm -rf "${ROOT_DIR}/resource"
	msg "Copying clang resource ..."
	cp -r "${NDK_CLANG_RESOURCE}" "${ROOT_DIR}/resource"

	find "${ROOT_DIR}/resource/lib" -maxdepth 1 -mindepth 1 -not -name linux -exec rm -rf {} \;

	## Create target wrapper
	mkdir -p "${ROOT_DIR}/bin"
	find "${ROOT_DIR}/sysroot/usr/lib" -maxdepth 1 -mindepth 1 -type d | while IFS= read -r dir; do
		ANDROID_ABI=$(basename $dir)
		find "${dir}" -maxdepth 1 -mindepth 1 -type d | sort | while IFS= read -r digit_dir; do
			ANDROID_API=$(basename "${digit_dir}")
			msg "link ${ANDROID_ABI}${ANDROID_API}-clang"
			ln -snf "../wrappers/target_wrapper" "${ROOT_DIR}/bin/${ANDROID_ABI}${ANDROID_API}-clang"
			msg "link ${ANDROID_ABI}${ANDROID_API}-clang++"
			ln -snf "../wrappers/target_wrapper" "${ROOT_DIR}/bin/${ANDROID_ABI}${ANDROID_API}-clang++"
		done
	done
	cp "${ROOT_DIR}/wrappers/ld.android" "${ROOT_DIR}/bin/ld.android"
}

check() {
	msg "Checking NDK ..."
	TOOLCHAIN="${ROOT_DIR}"
	TARGET=aarch64-linux-android35

	${TOOLCHAIN}/bin/${TARGET}-clang ${ROOT_DIR}/tests/hello.c -o ${TMPDIR}/helloc
	${TOOLCHAIN}/bin/${TARGET}-clang++ ${ROOT_DIR}/tests/hello.cpp -o ${TMPDIR}/hellocpp
	${TOOLCHAIN}/bin/${TARGET}-clang ${ROOT_DIR}/tests/hello.c -o ${TMPDIR}/helloc-static -static
	${TOOLCHAIN}/bin/${TARGET}-clang++ ${ROOT_DIR}/tests/hello.cpp -o ${TMPDIR}/hellocpp-static -static
}

main() {
	if test $# -eq 1; then
		setup "$1"
		check
	else
		msg "Usage: ${PROGRAM} [ANDROID_NDK_ROOT]"
	fi
}

main "$@"
