#!/bin/sh
set -eu

## NOTES:
## On alpine, we should use gradle >= 8.8
## https://github.com/gradle/gradle/issues/24875
## On android, alpine openjdk > 17 may not work

ROOT_DIR=$(dirname $(realpath $0))
. $ROOT_DIR/utils.sh

setup() {
	PREFIX_DIR="$1"

	if ! command -v java >/dev/null; then
		msg "Cannot find java."
		exit 1
	fi

	msg "Setting up gradle ..."
	GRADLE_VERSION=8.9
	GRADLE_VARIANT=bin
	# GRADLE_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-${GRADLE_VARIANT}.zip
	GRADLE_URL=https://mirrors.cloud.tencent.com/gradle/gradle-${GRADLE_VERSION}-${GRADLE_VARIANT}.zip
	# GRADLE_URL=https://mirrors.huaweicloud.com/gradle/gradle-${GRADLE_VERSION}-${GRADLE_VARIANT}.zip

	GRADLE_ROOT=${PREFIX_DIR}/opt/gradle-${GRADLE_VERSION}
	gradle_archive="${TMPDIR}/gradle-${GRADLE_VERSION}.zip"
	if ! test -d "${GRADLE_ROOT}"; then
		if ! test -f "${gradle_archive}"; then
			${dl_cmd} "${GRADLE_URL}" >"${gradle_archive}"
		fi
		unzip -d "$(dirname ${GRADLE_ROOT})" "${gradle_archive}"
	fi

	msg "Checking gradle ..."
	"${GRADLE_ROOT}/bin/gradle" --version
}

if test $# -gt 0; then
	setup "$1"
else
	msg "Usage: $PROGRAM [PREFIX_DIR]"
fi
