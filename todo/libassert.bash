
__NS__generate_assert_functions() {
	if [[ -z $ASSERT || $ASSERT == 1 ]]; then
		__NS__assert() {
			local fmt=${1:-}
			if [[ $fmt != *'\n' ]]; then
				fmt+='\n'
			fi
			shift
			local -i exit_code=$?
			local file func
			local -i lineno
			local line
			local -i n=0
			local -i ctx=${ASSERT_CTX:-2} # number of context lines to print
			if (( exit_code != 0 )); then
				{
					file=$(readlink -e "${BASH_SOURCE[1]}")
					func=${FUNCNAME[1]}
					lineno=${BASH_LINENO[0]}
					printf 'Assertion (%i) at "%s:%i" in %s(): '"$fmt" $exit_code "$file" "$lineno" "$func" "$@"

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
				} | logfatal
				exit $exit_code
			fi 1>&2
			return 0
		}
	else
		__NS__assert() { return $?; }
	fi
}

__NS__assert() { return $?; }


__NS__generate_assert_functions

