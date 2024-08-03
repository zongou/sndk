<!-- # Android development on any platform

## For setting up SDK & NDK

Do you want to settting up SDK & NDK to compile android app on any platform?
Please look into this script [termux_setup_android_dev.sh](termux_setup_android_dev.sh)

On termux, Run this script [termux_setup_android_dev.sh](termux_setup_android_dev.sh) will do that for you.

## For compiling android targeted binary only

Want to know how does this work?
Please checkout [tests/test_toolchain.sh](tests/test_toolchain.sh)

### Instruction

Get NDK: [google site](https://developer.android.google.com/ndk/downloads) or [github site](https://github.com/android/ndk/releases)

Then run:

```sh
## Unzip android ndk to somewhere
unzip <android_ndk_package>

## Get resouce from ndk
./android-cross-toolchain.sh setup <path_to_ndk_root>
```

Get LLVM

- alpine:`apk add llvm lld`
- [zig](https://ziglang.org/download/):`export ZIG=<path_to_zig>`

- [static-clang](https://github.com/dzbarsky/static-clang/releases), [llvm-project](https://github.com/llvm/llvm-project/releases), [llvmbox](https://github.com/rsms/llvmbox/releases) or other llvm toolchain : `export PATH=${PATH}:<path_to_llvm_bin>`

Test toolchain

```sh
./bin/aarch64-linux-android21-clang tests/hello.c
./bin/aarch64-linux-android21-clang++ tests/hello.cpp
```

## Relavent links

- [Assembling a Complete Toolchain](https://clang.llvm.org/docs/Toolchain.html)
- [llvm-cross-toolchains](https://github.com/shengyun-zhou/llvm-cross-toolchains) -->

# What for?

On unsupported platform, such as android and aarch64-linux, do:

- [Compiling android application.](#for-compiling-android-application)
- [Compiling android C/C++ programs.](#for-compiling-cc-programs-only)

## How does it work?

We can make use of NDK prebuilted sysroot and clang resource dir with host clang toolchain.

```sh
TOOLCHAIN="<ANDROID_NDK_ROOT>/toolchains/llvm/prebuilt/linux-x86_64"
RESOURCE_DIR="${TOOLCHAIN}/lib/clang/<LLVM_VERSION>"
SYSROOT="${TOOLCHAIN}/sysroot"
TARGET="aarch64-linux-android21"

clang \
	-resource-dir "${RESOURCE_DIR}" \
	--sysroot="${SYSROOT}" \
	--target="${TARGET}" \
	-xc - \
	-o "hello-c" \
	<<-EOF
		#include <stdio.h>

		int main() {
		  printf("%s\n", "Hello, C!");
		  return 0;
		}
	EOF
```

## For compiling android application

### Setup SDK

First. Install JDK.

> **_NOTE that on android prooted alpine. jdk > 17 may not work_**

Then run

```sh
./setup_sdk.sh
```

### Setup NDK

First. Get NDK [official](https://developer.android.google.com/ndk/downloads) / [github](https://github.com/android/ndk/releases) and decompress

Then. Run

```sh
./setup_ndk.sh <ANDROID_NDK_ROOT>
```

### Get aapt2

Get aapt2 from https://github.com/ReVanced/aapt2/actions

> aapt2 is needed when building android application.

### Example: Compiling termux in prooted alpine

```sh
apt update
apt install git -y
git clone https://github.com/zongou/termux-app
cd termux-app
echo "ndk.dir=${ANDROID_NDK_ROOT}" >> local.properties
echo "android.aapt2FromMavenOverride=/usr/local/bin/aapt2 >> local.properties
./setup_gradle.sh
gradle assembleDebug
```

## For compiling C/C++ programs only

First. Get NDK [official](https://developer.android.google.com/ndk/downloads) / [github](https://github.com/android/ndk/releases) and decompress

Then. Run

```sh
./setup_toolchain.sh <ANDROID_NDK_ROOT>
```

### Test

```bash
./bin/aarch64-linux-android21-clang tests/hello.c -o hello-c
file hello-c
./bin/aarch64-linux-android21-clang++ tests/hello.cpp -o hello-cpp
file hello-cpp
```
