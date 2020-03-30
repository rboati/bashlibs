#!/bin/bash

# shellcheck disable=SC1091
source ../libimport.bash
DEBUG=1 bash_import ../libtest.bash


qsort() {
	(($#==0)) && return 0
	local stack=( 0 $(($#-1)) ) beg end i pivot smaller larger
	qsort_ret=("$@")
	while ((${#stack[@]})); do
		beg=${stack[0]}
		end=${stack[1]}
		stack=( "${stack[@]:2}" )
		smaller=() larger=()
		pivot=${qsort_ret[beg]}
		for ((i=beg+1;i<=end;++i)); do
			if [[ "${qsort_ret[i]}" < "$pivot" ]]; then
				smaller+=( "${qsort_ret[i]}" )
			else
				larger+=( "${qsort_ret[i]}" )
			fi
		done
		qsort_ret=( "${qsort_ret[@]:0:beg}" "${smaller[@]}" "$pivot" "${larger[@]}" "${qsort_ret[@]:end+1}" )
		if ((${#smaller[@]}>=2)); then stack+=( "$beg" "$((beg+${#smaller[@]}-1))" ); fi
		if ((${#larger[@]}>=2)); then stack+=( "$((end-${#larger[@]}+1))" "$end" ); fi
	done
}

testsuite_aaa_setup() {
	declare -ga ARRAY=( b e "c c" d a g f )
	declare -ga EXPECTED=( a b "c c" d e f g )
	A="\$B"
	B="b"
	NUM1=1
	NUM2=2
}

testsuite_aaa_teardown() {
	unset ARRAY
}

testsuite_aaa_test_sort1() {
	local -a qsort_ret
	qsort "${ARRAY[@]}"
	ARRAY=( "${qsort_ret[@]}" )

	[[ ${ARRAY[0]} == a ]] || test_assert
	[[ $NUM1 -gt $NUM2 ]] || test_assert
}

testsuite_aaa_test_sort2() {
	local -a qsort_ret
	qsort "${ARRAY[@]}"
	ARRAY=( "${qsort_ret[@]}" )

	test_assert_eval "match_declare ARRAY EXPECTED"
	test_assert_match_declare ARRAY EXPECTED
	test_assert_eq "${ARRAY[0]}" a
	test_assert_eq "${ARRAY[2]}" 'c c'
	test_assert_neq "$A" "$B"
}

testsuite_aaa_test_sort2() {
	local -a qsort_ret
	qsort "${ARRAY[@]}"
	ARRAY=( "${qsort_ret[@]}" )

	test_assert_eval "match_declare ARRAY EXPECTED"
	test_assert_match_declare ARRAY EXPECTED
	test_assert_eq "${ARRAY[0]}" a
	test_assert_eq "${ARRAY[2]}" 'c c'
	test_assert_neq "$A" "$B"
}


run_tests
print_test_results
