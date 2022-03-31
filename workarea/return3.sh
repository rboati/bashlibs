#!/bin/bash

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
				# shellcheck disable=SC2086,SC2015,SC1083
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

# Assign variables one scope above the caller
# Usage: local varname [varname ...] &&
#        upvars [-v varname value] | [-aN varname [value ...]] ...
# Available OPTIONS:
#     -aN  Assign next N values to varname as array
#     -v   Assign single value to varname
# Return: 1 if error occurs
# Example:
#
#    f() { local a b; g a b; declare -p a b; }
#    g() {
#        local c=( foo bar )
#        local "$1" "$2" && upvars -v $1 A -a${#c[@]} $2 "${c[@]}"
#    }
#    f  # Ok: a=A, b=(foo bar)
#

upvars() {
	while (( $# )); do
		case $1 in
			-a*)
				# Error checking
				[[ ${1#-a} ]] || die '`%s'\'': missing number specifier' "$1"
				printf %d "${1#-a}" &> /dev/null || die '`%s'\'': invalid number specifier' "$1"
				# Assign array of -aN elements
				# shellcheck disable=SC2086,SC2015,SC1083
				[[ "$2" ]] && unset -v "$2" && eval $2=\(\"\${@:3:${1#-a}}\"\) && shift $((${1#-a} + 2)) || die '`%s'\'': missing argument(s)' "$1${2+ }$2"
				;;
			-A*)
				# Error checking
				[[ ${1#-A} ]] || die '`%s'\'': missing number specifier' "$1"
				printf %d "${1#-A}" &> /dev/null || die '`%s'\'': invalid number specifier' "$1"
				# Assign array of -AN elements
				# shellcheck disable=SC2015
				[[ "$2" ]] && upvar_hash "$2" "${@:3:${1#-A}*2}" && shift $((${1#-A}*2 + 2)) || die '`%s'\'': missing argument(s)' "$1${2+ }$2"
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
		eval "$1=( \"\${@:2}\" )"
	fi
}

# upvar_hash: {varname} {keys...} {values...}
upvar_hash() {
	if unset -v "${1:?}"; then
		while (( $# > 1 )); do
			eval "$1[${2@Q}]=\${$((($#-1)/2+2))}"
			set -- "$1" "${@:3:($#-1)/2-1}" "${@:($#-1)/2+3}"
		done
		: # set exit code to 0
	fi
}


fun_arr() {
	local ${retvar:-return} && upvar_array "${retvar:-return}" "${arr0[@]}"
}

fun_hash() {
	local ${retvar:-return} && upvars -A${#hash0[@]} "${retvar:-return}" "${!hash0[@]}" "${hash0[@]}"
}


declare -a arr0=(  " a b c " '1 "2" 3'   "d   \"e\"   f" "4 5 6"  "g h i" "7 8 9" )
declare -A hash0=( [ a b c ]='1 "2" 3'   [d   \"e\"   f]="4 5 6"  [g h i]="7 8 9" )

#declare -a arr1
#retvar=arr1  fun_arr
#declare -p arr0 arr1

declare -A hash1
retvar=hash1 fun_hash
declare -p hash0 hash1
