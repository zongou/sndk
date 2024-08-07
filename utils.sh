msg() { printf "%s\n" "$*" >&2; }

TMPDIR=${TMPDIR-/tmp}
PROGRAM=$(basename $0)

dl_cmd="curl -Lk"
if ! command -v curl >/dev/null && command -v wget >/dev/null; then
	dl_cmd="wget -O-"
fi
