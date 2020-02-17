#/bin/bash

source ../libimport.bash
ASSERT=0 bash_import ../libassert.bash

exit() {
	echo "Ignoring EXIT($1) for testing purposes"
}

function1() {
	assert test 10 -gt 5
	function2
}

function2() {
	assert false
}

for i in 1 2;  do
	if (( i == 1 )); then
		echo "Assertions disabled"
	elif (( i == 2 )); then
		ASSERT=1 generate_assert_functions
		echo "Assertions enabled"
	fi

	(( 30 < 5 )) || assert
	assert false
	assert true
	function1
done
