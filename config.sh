msg() { printf "%s\n" "$*" >&2; }

TMPDIR=${TMPDIR-/tmp}
PROGRAM=$(basename $0)

dl_cmd="curl -Lk"
if ! command -v curl >/dev/null && command -v wget >/dev/null; then
	dl_cmd="wget -O-"
fi

check_tools() {
	command_not_found=''
	for tool in "$@"; do
		msg "checking for $tool ..."
		if ! command -v "$tool" >/dev/null; then
			if test -z "$command_not_found"; then
				command_not_found="$tool"
			else
				command_not_found="${command_not_found}, $tool"
			fi
		fi
	done

	if [ -n "$command_not_found" ]; then
		msg "Error: Command not found: ${command_not_found}"
		exit 1
	fi
}

GRADLE_VERSION=8.8
GRADLE_VARIANT=bin
CMDLINETOOLS_VERSION=11076708
NDK_VERSION=r27b
