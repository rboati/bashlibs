


__NS__get_test_functions() {
	local prefix=$1
	local testfunc
	declare -F | while IFS=' ' read -r _ _ testfunc _; do
		if [[ $testfunc == testsuite_${prefix} ]]; then
			echo "$testfunc"
		fi
	done
}


__NS__run_tests() {
	declare -gAi __NS__TESTSUITES=()
	declare -gA __NS__TESTS=()
	local suite_pattern=${1:-*}
	#local TEST_PATTERN=${2:-*}
	local testfunc testsuite
	#local TEST
	local -i TEST_EXIT_CODE
	local -i count
	local testsuite testfunc
	for testfunc in $(__NS__get_test_functions "${suite_pattern}_test_*"); do
		testsuite=${testfunc#testsuite_}
		testsuite=${testsuite%%_test_*}
		__NS__TESTS[$testfunc]='-'
		count=${ALL_TESTSUITES[$testsuite]}
		if [[ -z $count ]]; then
			__NS__TESTSUITES[$testsuite]=1
		else
			__NS__TESTSUITES[$testsuite]=$(( count + 1 ))
		fi
	done
	unset -v count

	for testfunc in $(__NS__get_test_functions "${suite_pattern}_test_*"); do
		testsuite=${testfunc#testsuite_}
		testsuite=${testsuite%%_test_*}
		#TEST=${testfunc#testsuite_${testsuite}_test_}
		TEST_EXIT_CODE=0
		(
			local -r setup=$(__NS__get_test_functions "${testsuite}_setup")
			local -r teardown=$(__NS__get_test_functions "${testsuite}_teardown")
			if [[ -n $setup ]]; then
				$setup
			fi
			TEST_EXIT_CODE=0
			$testfunc
			if [[ -n $teardown ]]; then
				$teardown
			fi
			exit $TEST_EXIT_CODE
		)
		TEST_EXIT_CODE=$?
		if (( TEST_EXIT_CODE == 0 )); then
			__NS__TESTS[$testfunc]='SUCCESS'
		else
			__NS__TESTS[$testfunc]='FAIL'
		fi
	done
}


__NS__print_test_results() {
	local suite_pattern=${1:-*}
	#local TEST_PATTERN=${2:-*}
	local testfunc result
	local -i successes=0 failures=0 tested=0 untested=0 total=0
	local color

	for testfunc in $(__NS__get_test_functions "${suite_pattern}_test_*"); do
		result=${__NS__TESTS[$testfunc]}
		case $result in
			FAIL)    (( failures++  )) ; color='31' ;;
			SUCCESS) (( successes++ )) ; color='32' ;;
			-)       (( untested++  )) ; color='1'  ;;
		esac
		printf '%s: \e[%sm%s\e[0m\n' "$testfunc" "$color" "$result"
	done
	(( tested=successes+failures ))
	(( total=tested+untested ))
	local successes_percent=$((100*successes/tested )) failures_percent=$((100*failures/tested))
	if (( successes_percent != 100 )); then
		color=31
	else
		color=32
	fi
	successes_percent="\e[${color}m${successes_percent}%\e[0m"
	if (( failures_percent != 0 )); then
		color=31
	else
		color=32
	fi
	failures_percent="\e[${color}m${failures_percent}%\e[0m"

	printf '\e[37mSummary\e[0m: %d/%d successes (%b), %d/%d failures (%b), %d/%d tested (%d%%)\n' "$successes" "$tested" "$successes_percent" "$failures" "$tested" "$failures_percent" "$tested" "$total" $((100*tested/total))
}


__NS__print_test_summary() {
	local suite_pattern=${1:-*}
	#local TEST_PATTERN=${2:-*}
	local testfunc result
	local -i successes=0 failures=0 tested=0 untested=0 total=0
	local color

	for testfunc in $(__NS__get_test_functions "${suite_pattern}_test_*"); do
		result=${__NS__TESTS[$testfunc]}
		case $result in
			FAIL)    (( failures++  )) ; color='31' ;;
			SUCCESS) (( successes++ )) ; color='32' ;;
			-)       (( untested++  )) ; color='1'  ;;
		esac
	done
	(( tested=successes+failures ))
	(( total=tested+untested ))
	local successes_percent=$((100*successes/tested )) failures_percent=$((100*failures/tested))
	if (( successes_percent != 100 )); then
		color=31
	else
		color=32
	fi
	successes_percent="\e[${color}m${successes_percent}%\e[0m"
	if (( failures_percent != 0 )); then
		color=31
	else
		color=32
	fi
	failures_percent="\e[${color}m${failures_percent}%\e[0m"

	printf '\e[37mSummary\e[0m: %d/%d successes (%b), %d/%d failures (%b), %d/%d tested (%d%%)\n' "$successes" "$tested" "$successes_percent" "$failures" "$tested" "$failures_percent" "$tested" "$total" $((100*tested/total))
}





__NS__test_assert() {
	local -i exit_code=$?
	#[[ -v TEST_EXIT_CODE ]] && return 1
	local fmt=${1:-}
	if [[ $fmt != *'\n' ]]; then
		fmt+='\n'
	fi
	shift
	local file func line
	local -i lineno n=0 ctx=${ASSERT_CTX:-1}
	if (( exit_code != 0 )); then
		file=$(readlink -e "${BASH_SOURCE[1]}")
		func=${FUNCNAME[1]}
		lineno=${BASH_LINENO[0]}
		printf '%s: \e[31mFAIL\e[0m: Return code %d in %s:%d: '"$fmt" "$func" "$exit_code" "$file" "$lineno" "$@"
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
		TEST_EXIT_CODE=$exit_code
		exit $exit_code
	fi 1>&2
	return 0
}

