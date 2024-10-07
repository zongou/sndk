#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(realpath $0))
. ${ROOT_DIR}/config.sh

setup() {
	ANDROID_NDK_ROOT="$1"

	msg "Setting up NDK ..."
	check_tools clang clang++ ld.lld llvm-strip which make

	## Fix: ERROR: Unknown host CPU architecture: aarch64
	sed -i 's/arm64)/arm64|aarch64)/' "${ANDROID_NDK_ROOT}/build/tools/ndk_bin_common.sh"

	# ## Replace toolchain
	TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"

	## Create target wrapper
	rm -rf "${TOOLCHAIN}/bin" && mkdir "${TOOLCHAIN}/bin"
	cp "${ROOT_DIR}/wrappers/target_wrapper" "${TOOLCHAIN}/bin/target_wrapper"
	RESOURCE="$(find "${TOOLCHAIN}/lib/clang" -path "*/[0-9][0-9]" -type d -exec realpath {} \;)"
	sed -i "s^RESOURCE=.*^RESOURCE=${RESOURCE}^" "${TOOLCHAIN}/bin/target_wrapper"

	find "${TOOLCHAIN}/sysroot/usr/lib" -maxdepth 1 -mindepth 1 -type d | while IFS= read -r dir; do
		ANDROID_ABI=$(basename $dir)
		find "${dir}" -maxdepth 1 -mindepth 1 -type d | sort | while IFS= read -r digit_dir; do
			ANDROID_API=$(basename "${digit_dir}")
			msg "softlink ${ANDROID_ABI}${ANDROID_API}-clang"
			ln -snf "target_wrapper" "${TOOLCHAIN}/bin/${ANDROID_ABI}${ANDROID_API}-clang"
			msg "softlink ${ANDROID_ABI}${ANDROID_API}-clang++"
			ln -snf "target_wrapper" "${TOOLCHAIN}/bin/${ANDROID_ABI}${ANDROID_API}-clang++"
		done
	done

	# xz -d </storage/emulated/0/packages/toolchain/linux_arm64_minimal-v18.1.2-1.tar.xz | tar -C ${TOOLCHAIN} -xv bin

	# if ${CLANG-clang} -v 2>&1 | grep -q alpine; then
	# 	cp "${ROOT_DIR}/wrappers/alpine/ld.lld" "${TOOLCHAIN}/bin/ld.lld"
	# fi

	## Link llvm-wrapper
	find "${PREFIX-/usr}/bin" -name "llvm-*" | while IFS= read -r f; do
		msg "softlink $(basename $f)"
		ln -snf "$f" "${TOOLCHAIN}/bin/$(basename $f)"
	done

	ln -snf target_wrapper ${TOOLCHAIN}/bin/clang
	ln -snf target_wrapper ${TOOLCHAIN}/bin/clang++

	## Remove unused resource
	rm -rf "${TOOLCHAIN}/python3"
	rm -rf "${TOOLCHAIN}/musl"
	find "${TOOLCHAIN}/lib" -maxdepth 1 -mindepth 1 -not -name clang -exec rm -rf {} \;
	find "${TOOLCHAIN}" -maxdepth 5 -path "*/lib/clang/[0-9][0-9]/lib/*" -not -name linux -exec rm -rf {} \;

	## Replace python
	mkdir -p "${TOOLCHAIN}/python3/bin"
	if command -v python3 >/dev/null; then
		ln -snf "$(command -v python3)" "${TOOLCHAIN}/python3/bin/python3"
	else
		msg "Warning: Cannot find 'python3', ignored."
		cat <<-EOF >"${TOOLCHAIN}/python3/bin/python3"
			#!/bin/sh
			printf "dry run python with args: '%s' In dir: %s\n" "\$*" "\${PWD}" >&2
		EOF
		chmod +x "${TOOLCHAIN}/python3/bin/python3"
	fi
	cp "${ROOT_DIR}/wrappers/ld.android" "${TOOLCHAIN}/bin/ld.android"
}

check() {
	msg "Checking NDK ..."
	TOOLCHAIN="${1}/toolchains/llvm/prebuilt/linux-x86_64"
	TARGET=aarch64-linux-android35

	${TOOLCHAIN}/bin/${TARGET}-clang ${ROOT_DIR}/tests/hello.c -o ${TMPDIR}/helloc
	${TOOLCHAIN}/bin/${TARGET}-clang++ ${ROOT_DIR}/tests/hello.cpp -o ${TMPDIR}/hellocpp
	${TOOLCHAIN}/bin/${TARGET}-clang ${ROOT_DIR}/tests/hello.c -o ${TMPDIR}/helloc-static -static
	${TOOLCHAIN}/bin/${TARGET}-clang++ ${ROOT_DIR}/tests/hello.cpp -o ${TMPDIR}/hellocpp-static -static
}

if test $# -eq 1; then
	setup "$1"
	check "$1"
else
	msg "Usage: ${PROGRAM} [ANDROID_NDK_ROOT]"
fi
