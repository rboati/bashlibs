
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
	IFS=${3:-$' \t\n'} read -d '' -r -a "$2" <<< "$1"
	eval "$2[-1]=\${$2[-1]%\$'\\n'}"
}


function __NS__join_args {
	local sep=${1-} first=${2-}
	if shift 2; then
		printf -v __NS__join_args '%s' "$first" "${@/#/$sep}"
	fi
}


__NS__prefix_filter() {
	local prefix=$1
	# shellcheck disable=SC2034
	local line
	local template
	read -r -d '' template <<- EOF
		while read -r line; do
			printf -- '${prefix}%s\n' "\$line"
		done
	EOF
	eval "$template"
}




# $@: regex patterns to match
# exit code is 0 if one the patterns was found
# exit code is 1 otherwise
__NS__read_until() {
	local line regex
	while IFS='' read -r line ; do
		for regex in "$@"; do
			if [[ $line =~ $regex ]]; then
				return 0
			fi
		done
		printf '%s\n' "$line"
	done
	return 1
}



# $1: command to add
# $2: signal to trap
# returns the id of the added command
__NS__add_trap() {
	local cmd=${1?}
	local -u sig=${2?}
	sig=${sig#SIG}
	declare -ga "__NS__TRAP_$sig"
	local -n array=__NS__TRAP_$sig
	array+=( "$cmd" )
	local trap_output
	trap_output=$(trap -p "$sig")
	trap_output=${trap_output#trap -- \'}
	trap_output=${trap_output%\'*}
	local regex='\<__NS__execute_trap\> '"$sig"
	if [[ -z $trap_output ]]; then
		trap_output="__NS__execute_trap $sig"
		trap -- "$trap_output" "$sig"
	elif [[ ! $trap_output =~ $regex ]]; then
		trap_output="$trap_output;__NS__execute_trap $sig"
		trap -- "$trap_output" "$sig"
	fi
	local -a indexes=( "${!array[@]}" )
	local retvar=${retvar:=return} && upvar "$retvar" "${indexes[-1]}"
}

# Helper funciotn that executes all the commands queued for the specified signal
# $1: signal
__NS__execute_trap() {
	local sig=$1
	declare -ga "__NS__TRAP_$sig"
	local -n trap_array=__NS__TRAP_$sig
	local cmd
	set --
	for cmd in "${trap_array[@]}"; do
		$cmd
	done
}

