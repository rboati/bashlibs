
__NS__generate_assert_functions() {
	if [[ -z $ASSERT || $ASSERT == 1 ]]; then
		__NS__assert() {
			declare -i EXIT_CODE=$?
			declare arg FILE FUNC LINE
			{
				if (( $# == 0 )); then
					FILE="${BASH_SOURCE[1]}"
					FUNC="${FUNCNAME[1]}"
					LINE="${BASH_LINENO[0]}"
					printf 'Assert: "%s" in %s() [%s:%d]\n' "Exit code != 0" "$FUNC" "$FILE" "$LINE" 1>&2
					exit $EXIT_CODE
				fi

				if ! eval "$@"; then
					FILE="${BASH_SOURCE[1]}"
					FUNC="${FUNCNAME[1]}"
					LINE="${BASH_LINENO[0]}"
					printf 'Assert: "%s" in %s() [%s:%d]\n' "$*" "$FUNC" "$FILE" "$LINE" 1>&2
					exit -1
				fi
			} 1>&2
			return $EXIT_CODE
		}
	else
		__NS__assert() { return $?; }
	fi
}

__NS__undefined_function() {
	! declare -p -F "$1" &> /dev/null
}

__NS__undefined_var() {
	! declare -p "$1" &> /dev/null
}

__NS__assert() { return $?; }


__NS__generate_assert_functions


