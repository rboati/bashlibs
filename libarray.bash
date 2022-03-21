
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


__NS__zip_arrays() {
	: strip
	[[ -n ${1-} ]] || die 'Missing first indexed array'
	[[ -n ${2-} ]] || die 'Missing second indexed array'
	[[ $1 != __libarray_* ]] || die 'Parameter 1 must not start with reserved prefix __libarray_'
	[[ $2 != __libarray_* ]] || die 'Parameter 2 must not start with reserved prefix __libarray_'
	[[ ! -R $1 ]] || die 'Parameter 1 must not be a nameref'
	[[ ! -R $2 ]] || die 'Parameter 2 must not be a nameref'
	: endstrip
	local -n __libarray_1=$1 __libarray_2=$2
	: strip
	[[  ${__libarray_1@a} == *a* ]] || die 'Parameter 1 must be an indexed array'
	[[  ${__libarray_2@a} == *a* ]] || die 'Parameter 2 must be an indexed array'
	: endstrip
	local __libarray_retvar=${retvar:-return}
	: strip
	[[ ${__libarray_retvar} != __libarray_* ]] || die 'Return variable "retvar" not use the reserved prefix __libarray_'
	[[ ! -R ${__libarray_retvar} ]] || die 'Return variable "retvar" must not be a nameref'
	: endstrip
	local -n __libarray_retvar
	__libarray_retvar=()
	local -i __libarray_i __libarray_minlen __libarray_len1=${#__libarray_1[@]} __libarray_len2=${#__libarray_2[@]}
	if (( __libarray_len1 <= __libarray_len2 )); then __libarray_minlen=__libarray_len1; else __libarray_minlen=__libarray_len2; fi
	for (( __libarray_i=0; __libarray_i < __libarray_minlen; ++__libarray_i)); do __libarray_retvar+=( "${__libarray_1[__libarray_i]}" "${__libarray_2[__libarray_i]}" ); done
}


__NS__clone_function() {
	local oldname=${1:?} newname=${2:?}
	local fundecl=$(declare -f "$oldname" | { read -r _; printf -- '%s ()\n' "$newname"; cat; })
	eval "$fundecl"
}

__NS__in_array() {
	(( $# == 2 )) || die 'Missing arguments'
	[[ ${2:?} != __libarray_* ]] || die 'Parameter 2 must not use the reserved prefix __libarray_'
	local __libarray_value=$1
	local -n __libarray_arr=$2
	local -i i __libarray_len=${#__libarray_arr[@]}
	for ((i=0; i < __libarray_len; ++i)); do
		[[ ${__libarray_arr[i]} == "$__libarray_value" ]] && return 0
	done
	return 1
}


__NS__in_args() {
	(( $# > 0 )) || die 'Missing arguments'
	local value=$1 item
	shift
	for item; do
		[[ $item == "$value" ]] && return 0
	done
	return 1
}


