#!/bin/bash

# shellcheck disable=SC1091
source ../bashlibs.bash
bash_import ../libtest.bash


qsort() {
	(($# == 0)) && return 0
	local -ai stack=(0 "$# - 1")
	local -i beg end i
	local pivot
	local -a smaller larger qsort_ret=("$@")
	while ((${#stack[@]} > 0)); do
		beg=${stack[0]} end=${stack[1]}
		stack=("${stack[@]:2}")
		smaller=() larger=()
		pivot=${qsort_ret[beg]}
		for ((i = beg + 1; i <= end; ++i)); do
			if [[ ${qsort_ret[i]} < "$pivot" ]]; then
				smaller+=("${qsort_ret[i]}")
			else
				larger+=("${qsort_ret[i]}")
			fi
		done
		qsort_ret=("${qsort_ret[@]:0:beg}" "${smaller[@]}" "$pivot" "${larger[@]}" "${qsort_ret[@]:end+1}")
		((${#smaller[@]} >= 2)) && stack+=( beg "beg + ${#smaller[@]} - 1" )
		((${#larger[@]}  >= 2)) && stack+=( "end - ${#larger[@]} + 1" end )
	done
	local "${retvar:?}" && upvar_array "$retvar" "${qsort_ret[@]}"
}

testsuite_aaa_setup() {
	declare -ga ARRAY=(b e 'c c' d a g f)
	declare -ga EXPECTED=(a b 'c c' d e f g)
	declare -g A='$B'
	declare -g B='b'
	declare -gI NUM1=1
	declare -gI NUM2=2
}

testsuite_aaa_teardown() {
	unset ARRAY
}

testsuite_aaa_test_sort1() {
	local -a qsort_ret
	retvar=qsort_ret qsort "${ARRAY[@]}"
	ARRAY=( "${qsort_ret[@]}" )

	[[ ${ARRAY[0]} == a ]] || test_assert
	(( NUM1 > NUM2 )) || test_assert 'NUM1 is not greater than NUM2' #FAIL
}


declare_match() {
	set -- "$(declare -p "${1?}")" "$(declare -p "${2?}")"
	[[ ${1#*=} == "${2#*=}" ]]
}


testsuite_aaa_test_sort2() {
	local -a qsort_ret
	retvar=qsort_ret qsort "${ARRAY[@]}"
	ARRAY=( "${qsort_ret[@]}" )

	declare_match ARRAY EXPECTED || test_assert
	[[  ${ARRAY[0]} == a  ]] || test_assert
	[[  ${ARRAY[2]} == 'c c'  ]] || test_assert
	[[  $A != "$B"  ]] || test_assert
}


run_tests
print_test_results
