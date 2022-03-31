#!/bin/bash

# shellcheck disable=SC1091
source ../bashlibs.bash
ASSERT=1 bash_import ../libassert.bash

exit() {
	echo "Ignoring EXIT($1) for testing purposes"
}

is_function_set function1 || assert
function1() {
	test 10 -gt 5 || assert
	function2
}

! is_function_set function2 || assert
function2() {
	assert false
}


for i in 1 2;  do
	if (( i == 1 )); then
		ASSERT=1 generate_assert_functions
		echo "Assertions enabled"
	elif (( i == 2 )); then
		ASSERT=0 generate_assert_functions
		echo "Assertions disabled"
	fi

	(( 10 < 2 )) || assert

	(( 30 < 5 )) || assert

	false || assert
	true || assert

	false
	assert

	function1
done

