

declare -gA __NS__TESTSUITES=()
declare -gA __NS__TESTS=()


__NS__get_test_functions() {
	local PREFIX="$1"
	declare -F | while read -r X X TESTFUN X; do
		if [[ $TESTFUN == testsuite_${PREFIX} ]]; then
			echo "$TESTFUN"
		fi
	done
}

__NS__init_tests() {
	local SUITE_PATTERN="${1:-*}"
	local COUNT
	local TESTSUITE TESTFUNC
	for TESTFUNC in  $(__NS__get_test_functions ${SUITE_PATTERN}_test_*); do
		TESTSUITE="${TESTFUNC#testsuite_}"
		TESTSUITE="${TESTSUITE%%_test_*}"
		__NS__TESTS[$TESTFUNC]="-"
		COUNT=${ALL_TESTSUITES[$TESTSUITE]}
		if [[ -z $COUNT ]]; then
			__NS__TESTSUITES[$TESTSUITE]=1
		else
			__NS__TESTSUITES[$TESTSUITE]=$(( COUNT + 1 ))
		fi
	done
}


__NS__run_tests() {
	local SUITE_PATTERN="${1:-*}"
	local TEST_PATTERN="${2:-*}"
	local TESTFUNC TESTSUITE TEST
	local -i TEST_EXIT_CODE

	__NS__init_tests "${SUITE_PATTERN}"

	for TESTFUNC in $(__NS__get_test_functions "${SUITE_PATTERN}_test_*"); do
		TESTSUITE="${TESTFUNC#testsuite_}"
		TESTSUITE="${TESTSUITE%%_test_*}"
		TEST="${TESTFUNC#testsuite_${TESTSUITE}_test_}"
		TEST_EXIT_CODE=0
		(
			local -r SETUP=$(__NS__get_test_functions "${TESTSUITE}_setup")
			local -r TEARDOWN=$(__NS__get_test_functions "${TESTSUITE}_teardown")
			if [[ -n $SETUP ]]; then
				$SETUP
			fi
			TEST_EXIT_CODE=0
			$TESTFUNC
			if [[ -n $TEARDOWN ]]; then
				$TEARDOWN
			fi
			exit $TEST_EXIT_CODE
		)
		TEST_EXIT_CODE=$?
		if (( TEST_EXIT_CODE == 0 )); then
			__NS__TESTS[$TESTFUNC]="SUCCESS"
		else
			__NS__TESTS[$TESTFUNC]="FAIL"
		fi
	done
}

__NS__print_test_results() {
	local SUITE_PATTERN="${1:-*}"
	local TEST_PATTERN="${2:-*}"
	local TESTFUNC RESULT
	local -i SUCCESSES=0 FAILURES=0 TESTED=0 UNTESTED=0 TOTAL=0

	for TESTFUNC in $(__NS__get_test_functions "${SUITE_PATTERN}_test_*"); do
		RESULT=${__NS__TESTS[$TESTFUNC]}
		case $RESULT in
			FAIL)    let FAILURES++  ; COLOR='31' ;;
			SUCCESS) let SUCCESSES++ ; COLOR='32' ;;
			-)       let UNTESTED++  ; COLOR='1'  ;;
		esac
		printf '%s: \e[%sm%s\e[0m\n' $TESTFUNC "$COLOR" "$RESULT"
	done
	let TESTED=SUCCESSES+FAILURES
	let TOTAL=TESTED+UNTESTED
	printf "Totals: %d/%d successes (%d%%), %d/%d failures (%s%%), %d/%d tested (%d%%)\n" $SUCCESSES $TESTED $((100*SUCCESSES/TESTED )) $FAILURES $TESTED $((100*FAILURES/TESTED)) $TESTED $TOTAL $((100*TESTED/TOTAL))
}


__NS__test_assert() {
	local PREV_EXIT_CODE=$?
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	if (( $# == 0 )); then
		if (( PREV_EXIT_CODE != 0 )); then
			FILE="${BASH_SOURCE[1]}"
			FUNC="${FUNCNAME[1]}"
			LINE="${BASH_LINENO[0]}"
			printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "Exit code != 0" "$FUNC" "$FILE" "$LINE"
		fi
		TEST_EXIT_CODE=$PREV_EXIT_CODE
		exit $TEST_EXIT_CODE
	fi
	if ! eval "$*"; then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "$*" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}


__NS__match_declare() {
	local A1="$(declare -p "$1")"
	local A2="$(declare -p "$2")"
	[[ "${A1#*=}" == "${A2#*=}" ]]
	return $?
}

__NS__undefined_function() {
	! declare -p -F "$1" &> /dev/null
}

__NS__undefined_var() {
	! declare -p "$1" &> /dev/null
}


__NS__test_assert_match_declare() {
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	local A1="$(declare -p "$1")"
	local A2="$(declare -p "$2")"
	if ! [[ "${A1#*=}" == "${A2#*=}" ]]; then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "\$$1 match \$$2" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}

__NS__test_assert_eq() {
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	if ! [[ "$1" == "$2" ]]; then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "$1 == $2" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}

__NS__test_assert_neq() {
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	if [[ "$1" == "$2" ]]; then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "$1 != $2" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}

__NS__test_assert_lt() {
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	if ! (( "$1" < "$2" )); then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "$1 < $2" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}

__NS__test_assert_gt() {
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	if ! (( "$1" > "$2" )); then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "$1 > $2" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}

__NS__test_assert_le() {
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	if ! (( "$1" <= "$2" )); then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "$1 <= $2" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}

__NS__test_assert_ge() {
	[[ -z $TEST_EXIT_CODE ]] && return -1
	declare FILE FUNC LINE
	if ! (( "$1" >= "$2" )); then
		FILE="${BASH_SOURCE[1]}"
		FUNC="${FUNCNAME[1]}"
		LINE="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' $TESTFUNC "$1 >= $2" "$FUNC" "$FILE" "$LINE"
		TEST_EXIT_CODE=1
		exit $TEST_EXIT_CODE
	fi
}

