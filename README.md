# Android Build Enviroment

Build Android Application and Android targetd binary on unsupported os/arch.  
For example:

- [x] android
- [x] prooted linux distro on android
- [x] aarch64-linux

## Setup enviroment to build android app

### Setup SDK

First. Install JDK.

> **_NOTE that on android prooted alpine. jdk > 17 may not work_**

Then run

```sh
./setup_sdk.sh [PREFIX_DIR]
```

### Setup NDK

First. Get NDK [official](https://developer.android.google.com/ndk/downloads) / [github](https://github.com/android/ndk/releases) and decompress

Then. Run

```sh
./setup_ndk.sh [ANDROID_NDK_ROOT]
```

### Get aapt2

- https://github.com/ReVanced/aapt2/actions
- https://github.com/lzhiyong/android-sdk-tools/releases

> aapt2 is needed when building android application.

### Example: Compiling termux in prooted alpine

```sh
apt update
apt install git -y
git clone https://github.com/zongou/termux-app
cd termux-app
echo "ndk.dir=${ANDROID_NDK_ROOT}" >> local.properties
echo "android.aapt2FromMavenOverride=/usr/local/bin/aapt2 >> local.properties
gradlew assembleRelease
```

## Setup toolchain for compiling C/C++ programs only

First. Get NDK [official](https://developer.android.google.com/ndk/downloads) / [github](https://github.com/android/ndk/releases) and decompress

Then. Run

```sh
./setup_toolchain.sh [ANDROID_NDK_ROOT]
```

### Test

```bash
./bin/aarch64-linux-android21-clang tests/hello.c -o hello-c
file hello-c
./bin/aarch64-linux-android21-clang++ tests/hello.cpp -o hello-cpp
file hello-cpp
```

### How does it work?

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
