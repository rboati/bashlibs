


# Wrapper for command "declare" that checks for name conflicts
__NS__declare_s() {
	# Tricky argument rotation reusing $@ to avoid creating local variables and hence possible name conflicts
	while :; do
		case $1 in
		--)
			shift
			break
			;;
		-*f*) die 'Cannot declare functions!' ;;
		-*F*) die 'Cannot print!' ;;
		-*p*) die 'Cannot print!' ;;
		-*) ;;
		*) break ;;
		esac
		set -- "${@:2}" "$1"
	done
	[[ $1 == -* ]] && die 'Cannot print!'
	set -- "$@" '--'
	while [[ $1 != -* ]]; do
		set -- "${1%%=*}" "$@"
		[[ -v $1 ]] && die 'Variable %s already declared!' "$1"
		set -- "${@:3}" "$2"
	done
	declare "$@"
}

# declare_s A=1 B C=1 D
# declare -p A B C D
# declare_s -i B D E=2
# declare -p A B C D E


# $1: functionname
# returns if function exists
__NS__is_function_set() {
	declare -F -- "$1" &>/dev/null
}


# $1: varname
# Returns if varname (or the resolved varname, in case of nameref) has been declared.
__NS__is_var_declared() {
	pragma local_prefix x_
	local -n x_var=${1:?}
	while [[ -R ${!x_var} ]]; do
		local -n x_var=${!x_var}
	done
	declare -p -- "${!x_var}" &>/dev/null
}


# $1: varname
# Returns if varname (or the resolved varname, in case of nameref) is an indexed array.
__NS__is_var_array() {
	pragma local_prefix x_
	local -n x_var=$1
	[[ ${x_var@a} == *a* ]]
}

# $1: varname
# Returns if varname (or the resolved varname, in case of nameref) is an associative array.
__NS__is_var_hash() {
	pragma local_prefix x_
	local -n x_var=$1
	[[ ${x_var@a} == *A* ]]
}

# $1: varname
# retvar: the resolved varname
__NS__resolve_nameref() {
	pragma local_prefix x_
	local -n x_var=${1:?}
	while [[ -R ${!x_var} ]]; do
		local -n x_var=${!x_var}
	done
	local -n x_ret=${retvar:?}; x_ret=${!x_var}
}


# $1: varname
# retvar: is set with one of NAMEREF | INT | STRING | ARRAY of [INT|STRING] | HASH of [INT|STRING] | UNDECLARED.
__NS__var_type() {
	pragma local_prefix x_
	local -n x_var=${1:?}
	local -n x_ret=${retvar:?}
	if [[ -R ${!x_var} ]]; then
		x_ret='NAMEREF'
		return 0
	fi
	x_ret=''
	local x_attrs=${x_var@a}
	if [[ $x_attrs == *a* ]]; then
		x_ret='ARRAY of '
	elif [[ $x_attrs == *A* ]]; then
		x_ret='HASH of '
	fi
	if [[ $x_attrs == *i* ]]; then
		x_ret+='INT'
	elif declare -p -- "${!x_var}" &> /dev/null; then
		x_ret+='STRING'
	else
		x_ret+='UNDECLARED'
	fi
}

# $1: varname
# retvar: Is set with one of SET | UNSET (but declared) | UNDECLARED.
__NS__var_status() {
	pragma local_prefix x_
	local -n x_var=${1:?}
	local -n x_ret=${retvar:?}
	if [[ -v x_var ]]; then
		x_ret='SET'
	elif declare -p -- "$x_var" &> /dev/null; then
		x_ret='UNSET'
	else
		x_ret='UNDECLARED'
	fi
}
