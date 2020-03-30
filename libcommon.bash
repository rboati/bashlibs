
# $1: varname
# $2: (optional). string with char to trim, by default "[:space:]"
__NS__ltrim() {
	eval "$1=\"\${$1#\"\${$1%%[!${2:-[:space:]}]*}\"}\""
}


# $1: varname
# $2: (optional). string with char to trim, by default "[:space:]"
__NS__rtrim() {
	eval "$1=\"\${$1%\"\${$1##*[!${2:-[:space:]}]}\"}\""
}


# $1: varname
# $2: (optional). string with char to trim, by default "[:space:]"
__NS__trim() {
	ltrim "$@"
	rtrim "$@"
}


# $1: text
# $2: varname
# $3: (optional). string with char to trim, by default "[:space:]"
__NS__split_string() {
	IFS="${3:-$' \t\n'}" read -d '' -r -a "$2" <<< "$1"
	eval "$2[-1]=\${$2[-1]%\$'\\n'}"
}

__NS__join_array_v() {
	local VAROUT="$1"
	local VARNAME="$2"
	local SEP="$3"
	eval "printf -v $VAROUT \"%s${SEP}\" \"\${${VARNAME}[@]}\""
	eval "printf -v $VAROUT '%s' \"\${$VAROUT%\$'$SEP'}\""
}

__NS__join_array() {
	local VARNAME="$1"
	local SEP="$2"
	local OUT
	__NS__join_array_v OUT "$VARNAME" "$SEP"
	printf '%s' "$OUT"
}


__NS__generate_prefix_filter() {
	local NAME="$1"
	local PREFIX="$2"
	# shellcheck disable=SC2155
	local TEMPLATE="$(cat <<- EOF
		$NAME() {
			local LINE
			while read -r LINE; do
				printf '%s%s\n'  ${PREFIX@Q} "\$LINE"
			done
		}
		EOF
	)"
	eval "$TEMPLATE"
}
