
upvars() {
	if ! (( $# )); then
		echo "${FUNCNAME[0]}: usage: ${FUNCNAME[0]} [-v varname value] | [-aN varname [value ...]] ..." 1>&2
		die 'Missing arguments'
	fi
	while (( $# )); do
		case $1 in
			-a*)
				# Error checking
				[[ ${1#-a} ]] || die '`%s'\'': missing number specifier' "$1"
				printf %d "${1#-a}" &> /dev/null || die '`%s'\'': invalid number specifier' "$1"
				# Assign array of -aN elements
				# shellcheck disable=SC2086,SC2015
				[[ "$2" ]] && unset -v "$2" && eval $2=\(\"\${@:3:${1#-a}}\"\) && shift $((${1#-a} + 2)) || die '`%s'\'': missing argument(s)' "$1${2+ }$2"
				;;
			-A*)
				# Error checking
				[[ ${1#-A} ]] || die '`%s'\'': missing number specifier' "$1"
				printf %d "${1#-A}" &> /dev/null || die '`%s'\'': invalid number specifier' "$1"
				# Assign array of -aN elements
				# shellcheck disable=SC2086,SC2015
				[[ "$2" ]] && unset -v "$2" && eval $2=\( "${@:3:${1#-A}*2}" \) && shift $((${1#-A}*2 + 2)) || die '`%s'\'': missing argument(s)' "$1${2+ }$2"
				;;
			-v)
				# Assign single value
				# shellcheck disable=SC2086,SC2015
				[[ "$2" ]] && unset -v "$2" && eval $2=\"\$3\" && shift 3 || die '`%s'\'': missing argument(s)' "$1"
				;;
			--help) cat <<- EOF
				Usage: local varname [varname ...] &&
				${FUNCNAME[0]} [-v varname value] | [-a{N} varname [value ...]] | [-A{N} varname [key value ...]] ...
				Available OPTIONS:
				-a{N} VARNAME [value ...]  assign next N values to varname as array
				-A{N} VARNAME [value ...]  assign next N values to varname as associative array
				-v VARNAME value           assign single value to varname
				--help                     display this help and exit
				--version                  output version information and exit
				EOF
				return 0
				;;
			--version) cat <<- EOF
				${FUNCNAME[0]}-0.9.dev
				Copyright (C) 2010 Freddy Vulto
				License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
				This is free software: you are free to change and redistribute it.
				There is NO WARRANTY, to the extent permitted by law.
				EOF
				return 0
				;;
			*)
				die '`%s'\'': invalid option' "$1"
				;;
		esac
	done
}


upvar() {
	if unset -v "${1:?}"; then
		eval "$1"="${2?}"
	fi
}

upvar_array() {
	if unset -v "${1:?}"; then
		eval "$1=(" "${@:2}" ")"
	fi
}


set_exit_code() {
	return "${1:?0}"
}

die() {
	local -i exit_code=$?
	printf -- 'Exit (%i): %s: %s: '"${1:-}" $exit_code "${BASH_SOURCE[1]}" "${FUNCNAME[1]}" "${@:2}" >&2
	if [[ $1 != *'\n' ]]; then
		printf -- '\n' >&2
	fi
	if (( exit_code == 0 )); then
		exit_code=1
	fi
	exit $exit_code
}

function comment() {
	local -i exit_code=$?
	:
	return $exit_code
}


#region comment
comment <<- 'EOC'
Comment example
EOC
#endregion

# shopt -s expand_aliases
# alias begincomment="'comment' <<- 'endcomment'"

# begincomment
# Comment example
# xaasa
# endcomment


# declare wrapper that checks for conflicts
declare_g() {
	# Tricky argument rotation to avoid creating local variables
	# and hence possible conflicts
	while  [[ $1 == -* ]]; do
		[[ $1 == -- ]] && { shift; break; }
		[[ $1 != *f* ]] || die "Cannot declare functions!\n"
		set -- "${@:2}" "$1"
	done
	set -- "$@" "--"
	while  [[ $1 != -* ]]; do
		set -- "${1%%=*}" "$@"
		[[ ! -v $1 ]] || die "Global variable %s already exists!\n" "$1"
		set -- "${@:3}" "$2"
	done
	declare -g "$@"
}

# declare_g A=1 B C=1 D
# declare -p A B C D
# declare_g -i B D E=2
# declare -p A B C D E


