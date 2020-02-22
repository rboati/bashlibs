
# $1: varname
# $2: (optional). string with char to trim, by default "[:space:]"
__NS__triml() {
	eval "$var=\"\${$1#\"\${$1%%[!${2:-[:space:]}]*}\"}\""
}


# $1: varname
# $2: (optional). string with char to trim, by default "[:space:]"
__NS__trimr() {
	eval "$var=\"\${$1%\"\${$1##*[!${2:-[:space:]}]}\"}\""
}


# $1: varname
# $2: (optional). string with char to trim, by default "[:space:]"
__NS__trim() {
	triml "$@"
	trimr "$@"
}


# $1: text
# $2: varname
# $3: (optional). string with char to trim, by default "[:space:]"
__NS__split_string() {
	IFS="${3:-$' \t\n'}" read -d '' -r -a "$2" <<< "$1"
	eval "$2[-1]=\${$2[-1]%\$'\\n'}"
}

__NS__join_array_v() {
	local varout="$1"
	local varname="$2"
	local sep="$3"
	eval "printf -v $varout \"%s${sep}\" \"\${$varname[@]}\""
	eval "printf -v $varout '%s' \"\${$varout%\$'$sep'}\""
}

__NS__join_array() {
	local varname="$1"
	local sep="$2"
	local out
	__NS__join_array_v out "$varname" "$sep"
	printf '%s' "$out"
}
