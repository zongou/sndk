#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(realpath $0))
. $ROOT_DIR/utils.sh

setup() {
	ANDROID_NDK_ROOT="$1"

	if ! command -v clang >/dev/null; then
		msg "Cannot find clang."
		exit 1
	fi

	for tool in clang clang++ ld.lld which make; do
		if ! command -v "${tool}" >/dev/null; then
			msg "Cannot find '${tool}'"
			exit 1
		fi
	done

	msg "Setting up NDK ..."
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

	## Create target wrapper
	rm -rf "${TOOLCHAIN}/bin" && mkdir "${TOOLCHAIN}/bin"
	cp "${ROOT_DIR}/wrappers/target_wrapper" "${TOOLCHAIN}/bin/clang"
	NDK_CLANG_RESOURCE="$(find "${TOOLCHAIN}/lib/clang" -path "*/[0-9][0-9]" -type d -exec realpath {} \;)"
	sed -i "s^RESOURCE_DIR=.*^RESOURCE_DIR=${NDK_CLANG_RESOURCE}^" "${TOOLCHAIN}/bin/clang"
	ln -snf "clang" "${TOOLCHAIN}/bin/clang++"

	if ${CLANG-clang} -v 2>&1 | grep -q alpine; then
		cp "${ROOT_DIR}/wrappers/alpine/ld.lld" "${TOOLCHAIN}/bin/ld.lld"
	fi

	find "${TOOLCHAIN}/sysroot/usr/lib" -maxdepth 1 -mindepth 1 -type d | while IFS= read -r dir; do
		ANDROID_ABI=$(basename $dir)
		find "${dir}" -maxdepth 1 -mindepth 1 -type d | sort | while IFS= read -r di; do
			ANDROID_API=$(basename "$di")
			msg "softlink ${ANDROID_ABI}${ANDROID_API}-clang"
			ln -snf "clang" "${TOOLCHAIN}/bin/${ANDROID_ABI}${ANDROID_API}-clang"
			msg "softlink ${ANDROID_ABI}${ANDROID_API}-clang++"
			ln -snf "clang" "${TOOLCHAIN}/bin/${ANDROID_ABI}${ANDROID_API}-clang++"
		done
	done

	## Link llvm-wrapper
	find "${PREFIX-/usr}/bin" -name "llvm-*" | while IFS= read -r f; do
		msg "softlink $(basename $f)"
		ln -snf "$f" "${TOOLCHAIN}/bin/$(basename $f)"
	done

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
		msg "Warning: Cannot find 'python3'"
		cat <<-EOF >"${TOOLCHAIN}/python3/bin/python3"
			printf "Called python with args: '%s'\nIn dir: %s\n" "\$*" "\${PWD}" >&2
		EOF
		chmod +x "${TOOLCHAIN}/python3/bin/python3"
	fi
}

check() {
	msg "Checking NDK ..."
	TOOLCHAIN="${1}/toolchains/llvm/prebuilt/linux-x86_64"

	${TOOLCHAIN}/bin/aarch64-linux-android21-clang ${ROOT_DIR}/tests/hello.c -o ${TMPDIR}/helloc
	file ${TMPDIR}/helloc

	${TOOLCHAIN}/bin/aarch64-linux-android21-clang++ ${ROOT_DIR}/tests/hello.cpp -o ${TMPDIR}/hellocpp
	file ${TMPDIR}/hellocpp

	${TOOLCHAIN}/bin/aarch64-linux-android21-clang ${ROOT_DIR}/tests/hello.c -o ${TMPDIR}/helloc-static -static
	file ${TMPDIR}/helloc-static

	${TOOLCHAIN}/bin/aarch64-linux-android24-clang++ ${ROOT_DIR}/tests/hello.cpp -o ${TMPDIR}/hellocpp-static -static
	file ${TMPDIR}/hellocpp-static
}

if test $# -eq 1; then
	setup "$1"
	check "$1"
else
	msg "Usage: ${PROGRAM} [ANDROID_NDK_ROOT]"
fi
