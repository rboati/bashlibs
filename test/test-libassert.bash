#/bin/bash


source ../libimport.bash


ASSERT=0 bash_import ../libassert.bash
echo "Assertions disabled"

exit() {
	echo "Ignoring EXIT($1) for testing purposes"
}

function1() {
	assert "(( 10 < 5 ))"
	function2
}

function2() {
	assert "false"
}

assert "(( 30 < 5 ))"
assert "true"
function1


generate_assert_functions
echo "Assertions enabled"

assert "(( 30 < 5 ))"
assert "true"
function1
