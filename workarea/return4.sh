#!/bin/bash


# For original concept see https://www.fvue.nl/wiki/Bash:_Passing_variables_by_reference
# Usage: local $retvar && retvar {value}
retvar() {
	# shellcheck disable=SC2154
	unset -v "$retvar" &> /dev/null || { printf 'Error: Missing or invalid retvar\n' >&2; return 1; }
	[[ -R $retvar ]] && { printf 'Error: Return var %s cannot be a reference\n' "$retvar" >&2; return 2; }
	printf -v "$retvar" -- '%s' "$1"
}

# Usage: local $retvar && retvar_array "${my_list[@]}"
retvar_array() {
	# shellcheck disable=SC2154
	unset -v "$retvar" &> /dev/null || { printf 'Error: Missing or invalid retvar\n' >&2; return 1; }
	[[ -R $retvar ]] && { printf 'Error: Return var %s cannot be a reference\n' "$retvar" >&2; return 2; }
	eval "[[ \${$retvar@a} == *A* ]]" && { printf 'Error: Return var %s cannot be an associative array\n' "$retvar" >&2; return 3; }
	eval "$retvar=( ${*@Q} )"
}

# Usage: local $retvar && retvar_assoc "${my_map[@]@k}"
retvar_assoc() {
	# shellcheck disable=SC2154
	unset -v "$retvar" &> /dev/null || { printf 'Error: Missing or invalid retvar\n' >&2; return 1; }
	[[ -R $retvar ]] && { printf 'Error: Return var %s cannot be a reference\n' "$retvar" >&2; return 2; }
	eval "[[ \${$retvar@a} != *A* ]]" && { printf 'Error: Return var %s is not an associative array\n' "$retvar" >&2; return 4; }
	eval "$retvar=( ${*@Q} )"
}

# Usage: local $retvar && retvar_array "${my_list[@]}"
retvar2() {
	# shellcheck disable=SC2154
	unset -v "$retvar" &> /dev/null || { printf 'Error: Missing or invalid retvar\n' >&2; return 1; }
	[[ -R $retvar ]] && { printf 'Error: Return var %s cannot be a reference\n' "$retvar" >&2; return 2; }
	if (( $# == 1 )); then
		printf -v "$retvar" -- '%s' "$1"
	else
		eval "$retvar=( ${*@Q} )"
	fi
}

retvars() {
	local -i i=0
	while (( $# > 0 )); do
		printf '$1=%s\n' "$1"
		case $1 in
		-v)
			shift
			unset -v "$1" &> /dev/null || { printf 'Error: Missing or invalid retvar\n' >&2; return 1; }
			[[ -R $1 ]] && { printf 'Error: Return var %s cannot be a reference\n' "$1" >&2; return 2; }
			printf -v "$1" -- '%s' "$2"
			shift 2
			;;
		-a)
			shift
			unset -v "$2" &> /dev/null || { printf 'Error: Missing or invalid retvar\n' >&2; return 1; }
			[[ -R $2 ]] && { printf 'Error: Return var %s cannot be a reference\n' "$2" >&2; return 2; }
			#1:len, 2:var, 3:val1, 4:val2, ...
			eval "$2=( \"\${@:3:$1}\" )"
			shift $(($1 + 2))
			;;
		-A)
			shift
			#unset -v "$2" &> /dev/null || { printf 'Error: Missing or invalid retvar\n' >&2; return 1; }
			#[[ -R $2 ]] && { printf 'Error: Return var %s cannot be a reference\n' "$2" >&2; return 2; }
			#1:len, 2:var, 3:val1, 4:val2, ...
			#eval "$2=( \"\${@:3:$1 * 2}\" )"
			local $retvar && retvar=$2 retvar_assoc "${@:3}"
			shift $(($1 * 2 + 2))
			;;
		esac
		((i++))
		((i>20)) && exit
	done
}



myfun() {
	local local_var=" \" ;? aa"
	printf 'EXPECTED: %s\n' "$(declare -p local_var)"
	local $retvar && retvar "$local_var"
}

myfun_array() {
	local -a local_array=(1 2 3 ');' 'ls' )
	printf 'EXPECTED: %s\n' "$(declare -p local_array)"
	local $retvar && retvar2 "${local_array[@]}"
}

myfun_assoc() {
	local -A local_assoc=([a a]="1 1" [b );ls]="  2 2  "  [c c]='3");ls')
	printf 'EXPECTED: %s\n' "$(declare -p local_assoc)"
	local $retvar && retvar_assoc "${local_assoc[@]@k}"
}

myfun_multi() {
	local la="hello"
	local -a lb=(1 2 3)
	local -A lc=(a '1;1' b');' 2');' c 3)
	printf 'EXPECTED: %s\n' "$(declare -p la lb lc)"
	local $1 $2 $3 && retvars -v $1 "$la" -a ${#lb[@]} $2 "${lb[@]}" -A ${#lc[@]} $3 "${lc[@]@k}"
}


false && {
	declare var
	retvar=var myfun
	printf 'GOT: %s\n' "$(declare -p var)"
	printf -- '-----------\n'
}

false && {
	declare -a array
	retvar=array myfun_array
	printf 'GOT: %s\n' "$(declare -p array)"
	printf -- '-----------\n'
}

false && {
	declare -A assoc
	retvar=assoc myfun_assoc
	printf 'GOT: %s\n' "$(declare -p assoc)"
	printf -- '-----------\n'
}

true && {
	declare a
	declare -a b
	declare -A c
	myfun_multi a b c
	printf 'GOT: %s\n' "$(declare -p a b c)"
	printf -- '-----------\n'

}