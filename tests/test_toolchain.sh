#!/bin/sh
set -eu

ROOT_DIR=$(dirname $(dirname $(realpath $0)))

## ndk clang resource dir, get by command: <ndk_root>/toolchains/llvm/prebuilt/linux-x86_64/bin/clang --print-resource-dir
RESOURCE_DIR="${ROOT_DIR}/resource"

## ndk sysroot, typically <ndk_root>/toolchains/llvm/prebuilt/linux-x86_64/sysroot/
SYSROOT="${ROOT_DIR}/sysroot"

## Android target triple
TARGET=aarch64-linux-android21

if command -v clang; then
	CLANG=clang
elif command -v zig; then
	CLANG="zig clang"
else
	print "Cannot find clang or zig\n" >&2
	exit 1
fi

## These options are needed for llvmbox
# -isystem "${SYSROOT}/usr/include/c++/v1" \
# -isystem "${SYSROOT}/usr/include" \
# -isystem "${SYSROOT}/usr/include/aarch64-linux-android"

mkdir -p "${ROOT_DIR}/tests/output"

echo "Test C compiler..."
${CLANG} \
	-B "${ROOT_DIR}/bin" \
	-resource-dir "${RESOURCE_DIR}" \
	--sysroot="${SYSROOT}" \
	--target="${TARGET}" \
	-xc - \
	"$@" \
	-o "${ROOT_DIR}/tests/output/hello-c" \
	<<-EOF
		#include <stdio.h>

		int main() {
		  printf("%s\n", "Hello, C!");
		  return 0;
		}
	EOF

echo "Test C++ compiler..."
${CLANG} \
	-B "${ROOT_DIR}/bin" \
	-resource-dir "${RESOURCE_DIR}" \
	--sysroot="${SYSROOT}" \
	--target="${TARGET}" \
	-xc++ -lc++ - \
	"$@" \
	-o "${ROOT_DIR}/tests/output/hello-cpp" \
	<<-EOF
		#include <iostream>
		using namespace std;

		int main() {
		  cout << "Hello, C++!\n";
		  return 0;
		}
	EOF

if command -v file >/dev/null; then
	file "${ROOT_DIR}/tests/output/hello-c" "${ROOT_DIR}/tests/output/hello-cpp"
fi
