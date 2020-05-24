

declare -gA __NS__TESTSUITES=()
declare -gA __NS__TESTS=()


__NS__get_test_functions() {
	local prefix="$1"
	local _ testfunc
	declare -F | while IFS=' ' read -r _ _ testfunc _; do
		if [[ $testfunc == testsuite_${prefix} ]]; then
			echo "$testfunc"
		fi
	done
}

__NS__init_tests() {
	local suite_pattern="${1:-*}"
	local count
	local testsuite testfunc
	for testfunc in  $(__NS__get_test_functions "${suite_pattern}_test_*"); do
		testsuite="${testfunc#testsuite_}"
		testsuite="${testsuite%%_test_*}"
		__NS__TESTS[$testfunc]="-"
		count=${ALL_TESTSUITES[$testsuite]}
		if [[ -z $count ]]; then
			# shellcheck disable=SC2034
			__NS__TESTSUITES[$testsuite]=1
		else
			# shellcheck disable=SC2034
			__NS__TESTSUITES[$testsuite]=$(( count + 1 ))
		fi
	done
}


__NS__run_tests() {
	local suite_pattern="${1:-*}"
	#local TEST_PATTERN="${2:-*}"
	local testfunc testsuite
	#local TEST
	local -i test_exit_code

	__NS__init_tests "${suite_pattern}"

	for testfunc in $(__NS__get_test_functions "${suite_pattern}_test_*"); do
		testsuite="${testfunc#testsuite_}"
		testsuite="${testsuite%%_test_*}"
		#TEST="${testfunc#testsuite_${testsuite}_test_}"
		test_exit_code=0
		(
			local -r setup=$(__NS__get_test_functions "${testsuite}_setup")
			local -r teardown=$(__NS__get_test_functions "${testsuite}_teardown")
			if [[ -n $setup ]]; then
				$setup
			fi
			test_exit_code=0
			$testfunc
			if [[ -n $teardown ]]; then
				$teardown
			fi
			exit $test_exit_code
		)
		test_exit_code=$?
		if (( test_exit_code == 0 )); then
			__NS__TESTS[$testfunc]="SUCCESS"
		else
			__NS__TESTS[$testfunc]="FAIL"
		fi
	done
}

__NS__print_test_results() {
	local suite_pattern="${1:-*}"
	#local TEST_PATTERN="${2:-*}"
	local testfunc result
	local -i successes=0 failures=0 tested=0 untested=0 total=0

	for testfunc in $(__NS__get_test_functions "${suite_pattern}_test_*"); do
		result=${__NS__TESTS[$testfunc]}
		case $result in
			FAIL)    (( failures++  )) ; COLOR='31' ;;
			SUCCESS) (( successes++ )) ; COLOR='32' ;;
			-)       (( untested++  )) ; COLOR='1'  ;;
		esac
		printf '%s: \e[%sm%s\e[0m\n' "$testfunc" "$COLOR" "$result"
	done
	(( tested=successes+failures ))
	(( total=tested+untested ))
	printf "Totals: %d/%d successes (%d%%), %d/%d failures (%s%%), %d/%d tested (%d%%)\n" "$successes" "$tested" $((100*successes/tested )) "$failures" "$tested" $((100*failures/tested)) "$tested" "$total" $((100*tested/total))
}


__NS__test_assert() {
	local prev_exit_code=$?
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	if (( $# == 0 )); then
		if (( prev_exit_code != 0 )); then
			file="${BASH_SOURCE[1]}"
			func="${FUNCNAME[1]}"
			line="${BASH_LINENO[0]}"
			printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "Exit code != 0" "$func" "$file" "$line"
		fi
		test_exit_code=$prev_exit_code
		exit $test_exit_code
	fi
	if ! eval "$*"; then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "$*" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}


__NS__match_declare() {
	# shellcheck disable=SC2155
	local A1="$(declare -p "$1")"
	# shellcheck disable=SC2155
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
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	# shellcheck disable=SC2155
	local A1="$(declare -p "$1")"
	# shellcheck disable=SC2155
	local A2="$(declare -p "$2")"
	if ! [[ "${A1#*=}" == "${A2#*=}" ]]; then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "\$$1 match \$$2" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}

__NS__test_assert_eq() {
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	if ! [[ "$1" == "$2" ]]; then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "$1 == $2" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}

__NS__test_assert_neq() {
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	if [[ "$1" == "$2" ]]; then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "$1 != $2" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}

__NS__test_assert_lt() {
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	if ! (( "$1" < "$2" )); then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "$1 < $2" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}

__NS__test_assert_gt() {
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	if ! (( "$1" > "$2" )); then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "$1 > $2" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}

__NS__test_assert_le() {
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	if ! (( "$1" <= "$2" )); then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "$1 <= $2" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}

__NS__test_assert_ge() {
	[[ -z $test_exit_code ]] && return 1
	declare file func line
	if ! (( "$1" >= "$2" )); then
		file="${BASH_SOURCE[1]}"
		func="${FUNCNAME[1]}"
		line="${BASH_LINENO[0]}"
		printf '%s: \e[31mFAIL\e[0m "%s" in %s() [%s:%d]\n' "$testfunc" "$1 >= $2" "$func" "$file" "$line"
		test_exit_code=1
		exit $test_exit_code
	fi
}

