
__NS__generate_assert_functions() {
	if [[ -z $ASSERT || $ASSERT == 1 ]]; then
		__NS__assert() {
			declare -i EXIT_CODE=$?
			declare arg FILE FUNC LINE
			for arg in "$@"; do
				if ! eval "$arg"; then
					FILE="${BASH_SOURCE[1]}"
					FUNC="${FUNCNAME[1]}"
					LINE="${BASH_LINENO[0]}"
					printf 'Assert: "%s" in %s() [%s:%d]\n' "$*" "$FUNC" "$FILE" "$LINE"
					exit -1
				fi
			done 1>&2
			return $EXIT_CODE
		}
	else
		__NS__assert() { return $?; }
	fi
}

__NS__assert() { return $?; }

__NS__generate_assert_functions


