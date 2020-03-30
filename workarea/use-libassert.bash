#!/bin/bash

# shellcheck disable=SC1091
source ../libimport.bash
ASSERT=1 bash_import ../libassert.bash

exit() {
	echo "Ignoring EXIT($1) for testing purposes"
}

assert undefined_function function1
function1() {
	assert test 10 -gt 5
	function2
}

assert ! undefined_function function2
function2() {
	assert false
}

for i in 1 2;  do
	if (( i == 1 )); then
		echo "Assertions enabled"
	elif (( i == 2 )); then
		ASSERT=0 generate_assert_functions
		echo "Assertions disabled"
	fi

	assert "(( 10 < 2 ))"

	(( 30 < 5 )) || assert

	assert false
	assert true

	false
	assert

	function1
done

