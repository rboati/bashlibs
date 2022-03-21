
upvar() {
    if unset -v "$1"; then           # Unset & validate varname
        if (( $# == 2 )); then
            eval $1=\"\$2\"          # Return single value
        else
            eval $1=\(\"\${@:2}\"\)  # Return array
        fi
    fi
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
	if ! (( $# )); then
		echo "${FUNCNAME[0]}: usage: ${FUNCNAME[0]} [-v varname value] | [-aN varname [value ...]] ..." 1>&2
		return 2
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



__NS__clone_array() {
	[[ ${1:?} != __arr ]] || die 'Name __arr is reserved, it cannot be used'
	[[ ! -R $1 ]] || die 'Nameref not allowed in $1'
	local -n __arr=$1
	local retvar=${retvar:-return}
	[[ ! -R $retvar ]] || die 'Nameref not allowed for $retvar'
	[[  ${__arr@a} == *[aA]* ]] || die 'Argument $1 must be an array'
	# shellcheck disable=SC2068  # Shellcheck considers @K expansion as unsafe
	#local "$retvar" && upvars -A${#__arr[@]} "$retvar" ${__arr[@]@K}
	local "$retvar" && upvar_array "$retvar" ${__arr[@]@K}
}


# declare -A arr=( [a]="11" [b]="22" [c]="33" [d]=4 [e]=5 [f]=6 )
# declare -A return

# #declare -a arr=(     a     b     c     d     e )
# #declare -a arr=( [0]=a [1]=b [2]=c [3]=d [4]=e )
# #declare -a arr=( [0]=a [1]=b       [3]=d [4]=e )
# #declare -a return

# declare -p arr return
# __NS__clone_array arr
# declare -p arr return



__NS__zip_arrays_upvar() {
	[[ ${1:?} != __arr* ]] || die 'Parameter 1 must not use the reserved prefix __arr'
	[[ ${2:?} != __arr* ]] || die 'Parameter 2 must not use the reserved prefix __arr'
	[[ ! -R $1 ]] || die 'Parameter 1 must not be a nameref'
	[[ ! -R $2 ]] || die 'Parameter 2 must not be a nameref'
	local -n __arr1=$1 __arr2=$2
	[[  ${__arr1@a} == *a* ]] || die 'Parameter 1 must be an indexed array'
	[[  ${__arr2@a} == *a* ]] || die 'Parameter 2 must be an indexed array'
	local retvar=${retvar:-return}
	[[ ! -R $retvar ]] || die 'Return variable "retvar" must not be a nameref'
	local -a __arr3
	local -i __arri __arrminlen __arrlen1=${#__arr1[@]} __arrlen2=${#__arr2[@]}
	if (( __arrlen1 <= __arrlen2 )); then __arrminlen=__arrlen1; else __arrminlen=__arrlen2; fi
	for (( __arri=0; __arri < __arrminlen; ++__arri)); do __arr3+=( "${__arr1[__arri]}" "${__arr2[__arri]}" ); done
	local "$retvar" && upvar_array "$retvar" "${__arr3[@]}"
}

__NS__zip_arrays() {
	: begin strip
	[[ ${1:?} != __libarray_* ]] || die 'Parameter 1 must not use the reserved prefix __libarray_'
	[[ ${2:?} != __libarray_* ]] || die 'Parameter 2 must not use the reserved prefix __libarray_'
	[[ ! -R $1 ]] || die 'Parameter 1 must not be a nameref'
	[[ ! -R $2 ]] || die 'Parameter 2 must not be a nameref'
	: end strip
	local -n __libarray_1=$1 __libarray_2=$2
	: begin strip
	[[  ${__libarray_1@a} == *a* ]] || die 'Parameter 1 must be an indexed array'
	[[  ${__libarray_2@a} == *a* ]] || die 'Parameter 2 must be an indexed array'
	: end strip
	local __libarray_retvar=${retvar:-return}
	: begin strip
	[[ ${__libarray_retvar} != __libarray_* ]] || die 'Return variable "retvar" not use the reserved prefix __libarray_'
	[[ ! -R ${__libarray_retvar} ]] || die 'Return variable "retvar" must not be a nameref'
	: end strip
	local -n __libarray_retvar
	__libarray_retvar=()
	local -i __libarray_i __libarray_minlen __libarray_len1=${#__libarray_1[@]} __libarray_len2=${#__libarray_2[@]}
	if (( __libarray_len1 <= __libarray_len2 )); then __libarray_minlen=__libarray_len1; else __libarray_minlen=__libarray_len2; fi
	for (( __libarray_i=0; __libarray_i < __libarray_minlen; ++__libarray_i)); do __libarray_retvar+=( "${__libarray_1[__libarray_i]}" "${__libarray_2[__libarray_i]}" ); done
}


 __NS__zip_arrays_unsafe() {
	local -n __libarray_1=$1 __libarray_2=$2
	local -n __libarray_retvar=${retvar:-return}
	local -i __libarray_i __libarray_minlen __libarray_len1=${#__libarray_1[@]} __libarray_len2=${#__libarray_2[@]}
	if (( __libarray_len1 <= __libarray_len2 )); then __libarray_minlen=__libarray_len1; else __libarray_minlen=__libarray_len2; fi
	__libarray_retvar=()
	for (( __libarray_i=0; __libarray_i < __libarray_minlen; ++__libarray_i)); do __libarray_retvar+=( "${__libarray_1[__libarray_i]}" "${__libarray_2[__libarray_i]}" ); done
}

__NS__clone_function() {
	local oldname=${1:?} newname=${2:?} decl _
	local -i exit_code
	decl=$(declare -f "$oldname" | { read -r _; printf -- '%s ()\n' "$newname"; cat; })
	exit_code=$?
	if (( exit_code == 0 )); then
		eval "$decl"
	fi
}

__NS__strip_function() {
	local name=${1:?} decl
	decl=$(declare -pf "$name" | grep -v '|| die ' )
	eval "$decl"
}

__NS__strip_function() {
	local name=${1:?} decl line state=0
	decl=$(declare -pf "$name" | while read -r line; do
			case $state in
			0)
				if [[ $line == ': begin strip;' ]]; then
					state=1
					continue
				fi
				printf -- '%s\n' "$line"
				;;
			1)
				if [[ $line == ': end strip;' ]]; then
					state=0
					continue
				fi
				;;
			esac
		done
	)
	eval "$decl"
}



declare -pf __NS__zip_arrays
__NS__strip_function __NS__zip_arrays
declare -pf __NS__zip_arrays



__NS__clone_function __NS__zip_arrays_fast pippo

echo here
declare -F
echo here end

echo subshell
( declare -F )
echo subshell end

echo subprocess
bash --norc <<- EOF
set -x
declare -F
declare
EOF
echo subprocess end



declare -a a=( $(seq 1 5) )
declare -a b=( $(seq 1 5) )
declare -a c __ns__c
#declare -i i times=10000

 retvar=__ns__c __NS__zip_arrays a b
 declare -p a b c __ns__c


#time for ((i=0; i<times; ++i)); do
#	retvar=c __NS__zip_arrays_upvar a b
#done
#
#time for ((i=0; i<times; ++i)); do
#	retvar=c __NS__zip_arrays a b
#done
#
#time for ((i=0; i<times; ++i)); do
#	retvar=c __NS__zip_arrays_fast a b
#done

