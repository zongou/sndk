#!/bin/sh
set -eu

## NOTES:
## On alpine, we should use gradle >= 8.8
## https://github.com/gradle/gradle/issues/24875
## On android, alpine openjdk > 17 may not work

msg() { printf "%s\n" "$*" >&2; }

TMPDIR=${TMPDIR-/tmp}

dl_cmd="curl -Lk"
if ! command -v curl >/dev/null && command -v wget >/dev/null; then
	dl_cmd="wget -O-"
fi
# ==============================================================

if ! command -v java >/dev/null; then
	msg "Cannot find java."
	exit 1
fi

GRADLE_VERSION=8.9
GRADLE_VARIANT=bin
# GRADLE_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-${GRADLE_VARIANT}.zip
GRADLE_URL=https://mirrors.cloud.tencent.com/gradle/gradle-${GRADLE_VERSION}-${GRADLE_VARIANT}.zip
# GRADLE_URL=https://mirrors.huaweicloud.com/gradle/gradle-${GRADLE_VERSION}-${GRADLE_VARIANT}.zip

GRADLE_HOME=${PREFIX-}/opt/gradle-${GRADLE_VERSION}
gradle_archive="${TMPDIR}/gradle-${GRADLE_VERSION}.zip"
if ! test -d "${GRADLE_HOME}"; then
	if ! test -f "${gradle_archive}"; then
		${dl_cmd} "${GRADLE_URL}" >"${gradle_archive}"
	fi
	unzip -d "$(dirname ${GRADLE_HOME})" "${gradle_archive}"
fi

"${GRADLE_HOME}/bin/gradle" --version

# msg "Setting up gradle ..."
# if command -v apt >/dev/null && ! command -v aapt2 >/dev/null; then
# 	apt install -y aapt2
# fi

# mkdir -p "${HOME}/.gradle"
# GRADLE_CONFIG="${HOME}/.gradle/gradle.properties"
# cat <<EOF >"${GRADLE_CONFIG}"
# android.aapt2FromMavenOverride=$(command -v aapt2)
# EOF

# msg "GRADLE_CONFIG=${GRADLE_CONFIG}"
# msg "Run: cat \${GRADLE_CONFIG}"
# cat "${GRADLE_CONFIG}"
