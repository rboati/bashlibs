#/bin/bash


fun1() {
	echo -n "fun1 "; declare -p A # fun1 declare -- A="10"
	unset A
	echo -n "fun1 "; declare -p A # fun1 ./test-scope.bash: line 7: declare: A: not found
}

A=10
echo -n "main "; declare -p A # main declare -- A="10"
fun1
echo -n "main "; declare -p A # main declare -- A="10"
# Conclusion: fun 1 unset var of previous scope


fun2() {
	local A=20
	echo -n "fun2 "; declare -p A # fun2 declare -- A="20"
	unset A
	echo -n "fun2 "; declare -p A # fun2 declare -- A
}

A=10
echo -n "main "; declare -p A # main declare -- A="10"
fun2
echo -n "main "; declare -p A # main declare -- A="10"
# Conclusion: fun 2 unset var of local scope and previous var is no more visible
# but there is no error


fun3() {
	local A=20
	echo -n "fun3 "; declare -p A # fun3 declare -- A="20"
	unset A
	echo -n "fun3 "; declare -p A # fun3 declare -- A
	unset A
	echo -n "fun3 "; declare -p A # fun3 declare -- A
}

A=10
echo -n "main "; declare -p A # main declare -- A="10"
fun3
echo -n "main "; declare -p A # main declare -- A="10"
# Conclusion: fun 3 unset var of local scope and previous var is no more visible and unset'able
# but there is no error


fun4() {
	local A=20
	echo -n "fun4 "; declare -p A # fun4 declare -- A="20"
	fun5
	echo -n "fun4 "; declare -p A # fun4 declare -- A="20"

}

fun5() {
	echo -n "fun5 "; declare -p A # fun5 declare -- A="20"
	local A=30
	echo -n "fun5 "; declare -p A # fun5 declare -- A="30"
	unset A
	echo -n "fun5 "; declare -p A # fun5 declare -- A
}


A=10
echo -n "main "; declare -p A # main declare -- A="10"
fun4
echo -n "main "; declare -p A # main declare -- A="10"
# Conclusion: fun 4 and fun 5 unset var of local scope and previuos var is no more visible and unset'able
# but there is no error


fun6() {
	local B=10
	echo -n "fun6 "; declare -p B # fun6 declare -- B="10"
	unset B
	echo -n "fun6 "; declare -p B # fun6 declare -- B
}

echo -n "main "; declare -p B # main ./test-scope.bash: line 81: declare: B: not found
fun6
echo -n "main "; declare -p B # main ./test-scope.bash: line 83: declare: B: not found
# Conclusion: unsetting local variables doesn't make them unset but NULL,
# shadowed parent var will remain unaccessible