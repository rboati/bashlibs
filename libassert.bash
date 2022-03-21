
__NS__generate_assert_functions() {
	if [[ -z $ASSERT || $ASSERT == 1 ]]; then
		__NS__assert() {
			local -i exit_code=$?
			local msg=$1
			local file func
			local -i lineno
			local line
			local -i n=0
			local -i ctx=${ASSERT_CTX:-2} # number of context lines to print
			if (( exit_code != 0 )); then
				file=${BASH_SOURCE[1]}
				func=${FUNCNAME[1]}
				lineno=${BASH_LINENO[0]}
				printf 'Assertion in %s (see %s:%d)%s\n' "$func" "$file" "$lineno" "${msg:+: $msg}"
				if (( ctx >= 0 )); then
					[[ -r $file ]] && cat -n -- "$file" | sed -n "$((lineno - ctx)),+$((ctx * 2))p;$((lineno + ctx))q" | while read -r line; do
						if (( n++ == ctx )); then
							printf '%s\n' "$line"
						else
							printf '\e[2m%s\e[0m\n' "$line"
						fi
					done
					printf '\n'
				fi
				exit $exit_code
			fi 1>&2
			return 0
		}
	else
		__NS__assert() { return $?; }
	fi
}

__NS__is_function_set() {
	declare -p -F "$1" &> /dev/null
}

__NS__is_function_unset() {
	! declare -p -F "$1" &> /dev/null
}

if (( BASH_VERSINFO[0] > 4 || ( BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2 ) )); then
	__NS__is_var_set() {
		[[ -v $1 ]]
	}

	__NS__is_var_unset() {
		[[ ! -v $1 ]]
	}
else
	__NS__is_var_set() {
		eval "[[ -n \${$1+x} ]]"
	}

	__NS__is_var_unset() {
		eval "[[ -z \${$1+x} ]]"
	}
fi


__NS__is_var_declared() {
	declare -p "$1" &> /dev/null
}

__NS__is_var_undeclared() {
	! declare -p "$1" &> /dev/null
}




__NS__is_var_array() {
	[[ $(declare -p "$1" 2> /dev/null) =~ "^declare -a" ]]
}

__NS__is_var_hash() {
	[[ $(declare -p "$1" 2> /dev/null) =~ "^declare -A" ]]
}

__NS__resolve_var_reference() {
	local decl=$(declare -p "$1" 2> /dev/null)
	local name=''
	local reg='^declare -n [^=]+=\"([^\"]+)\"$'
	while [[ $decl =~ $reg ]]; do
		name=${BASH_REMATCH[1]}
		decl=$(declare -p "$name")
	done
	__NS__resolve_var_reference_output=${name:-$1}
}

__NS__vartype() {
	local var=$(declare -p "$1" 2> /dev/null)
	local reg='^declare -n [^=]+=\"([^\"]+)\"$'
	while [[ $var =~ $reg ]]; do
		var=$(declare -p "${BASH_REMATCH[1]}")
	done

	case "${var#declare -}" in
	a*) echo "ARRAY" ;;
	A*) echo "HASH" ;;
	i*) echo "INT" ;;
	x*) echo "EXPORT" ;;
	*)  echo "OTHER" ;;
	esac
}


__NS__set_exit_code() {
	local -i exit_code=${1-0}
	# shellcheck disable=SC2086
	return $exit_code
}

__NS__assert() { return $?; }


__NS__generate_assert_functions

