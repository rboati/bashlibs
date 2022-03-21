#!/bin/bash

# shellcheck disable=SC1091
source ../libimport.bash
ASSERT=1 bash_import ../libassert.bash
ASSERT_CTX=1

fun1() {
	echo -n "fun1 "; declare -p A # fun1 declare -- A="10"
	is_var_set A || assert
	unset A
	echo -n "fun1 "; declare -p A # fun1 ./test-scope.bash: line 7: declare: A: not found
	is_var_unset A || assert
}

is_var_unset A || assert
A=10
echo -n "main "; declare -p A # main declare -- A="10"
is_var_set A || assert
fun1
echo -n "main "; declare -p A # main declare -- A="10"
# Conclusion: fun 1 unset var of previous scope
is_var_unset A || assert


fun2() {
	local A=20
	echo -n "fun2 "; declare -p A # fun2 declare -- A="20"
	is_var_set A || assert
	unset A
	echo -n "fun2 "; declare -p A # fun2 declare -- A
	is_var_unset A || assert
}

A=10
echo -n "main "; declare -p A # main declare -- A="10"
is_var_set A || assert
fun2
echo -n "main "; declare -p A # main declare -- A="10"
is_var_set A || assert
# Conclusion: fun 2 only unset var of local scope and previous var is no more visible
# but "declare -p" doesn't return error


fun3() {
	local A=20
	echo -n "fun3 "; declare -p A # fun3 declare -- A="20"
	is_var_set A || assert
	unset A
	echo -n "fun3 "; declare -p A # fun3 declare -- A
	is_var_unset A || assert
	unset A
	echo -n "fun3 "; declare -p A # fun3 declare -- A
	is_var_unset A || assert

}

A=10
echo -n "main "; declare -p A # main declare -- A="10"
is_var_set A || assert
fun3
echo -n "main "; declare -p A # main declare -- A="10"
is_var_set A || assert
# Conclusion: fun 3 unset var of local scope and previous var is no more visible and unset'able
# but there is no error


fun4() {
	local A=20
	echo -n "fun4 "; declare -p A # fun4 declare -- A="20"
	is_var_set A || assert
	fun5
	echo -n "fun4 "; declare -p A # fun4 declare -- A="20"
	is_var_set A || assert
}

fun5() {
	echo -n "fun5 "; declare -p A # fun5 declare -- A="20"
	is_var_set A || assert
	local A=30
	echo -n "fun5 "; declare -p A # fun5 declare -- A="30"
	is_var_set A || assert
	unset A
	echo -n "fun5 "; declare -p A # fun5 declare -- A
	is_var_unset A || assert
}


A=10
echo -n "main "; declare -p A # main declare -- A="10"
is_var_set A || assert
fun4
echo -n "main "; declare -p A # main declare -- A="10"
is_var_set A || assert
# Conclusion: fun 4 and fun 5 unset var of local scope and previuos var is no more visible and unset'able
# but there is no error


fun6() {
	local B=10
	echo -n "fun6 "; declare -p B # fun6 declare -- B="10"
	is_var_set B || assert
	unset B
	echo -n "fun6 "; declare -p B # fun6 declare -- B
	is_var_unset B || assert
}

echo -n "main "; declare -p B # main ./test-scope.bash: line 81: declare: B: not found
is_var_unset B || assert
fun6
echo -n "main "; declare -p B # main ./test-scope.bash: line 83: declare: B: not found
is_var_unset B || assert
# Conclusion: unsetting local variables doesn't make them unset but NULL,
# shadowed parent var will remain unaccessible