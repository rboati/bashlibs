#!/bin/bash



is_def1() {
	declare -p "$1" &> /dev/null
}

is_def2() {
	eval "[[ -n \${$1+x} ]]"
}

is_def3() {
	[[ -v $1 ]]
}



fun1() {
	local a=0
	local b=
	local c
	echo fun1
	is_def1 a && printf 'is_def1? %s '  a || printf 'is_def1? %s '  _
	is_def1 b && printf          '%s '  b || printf          '%s '  _
	is_def1 c && printf          '%s '  c || printf          '%s '  _
	is_def1 d && printf          '%s\n' d || printf          '%s\n' _
	is_def2 a && printf 'is_def2? %s '  a || printf 'is_def2? %s '  _
	is_def2 b && printf          '%s '  b || printf          '%s '  _
	is_def2 c && printf          '%s '  c || printf          '%s '  _
	is_def2 c && printf          '%s\n' d || printf          '%s\n' _
	is_def3 a && printf 'is_def3? %s '  a || printf 'is_def3? %s '  _
	is_def3 b && printf          '%s '  b || printf          '%s '  _
	is_def3 c && printf          '%s '  c || printf          '%s '  _
	is_def3 c && printf          '%s\n' d || printf          '%s\n' _
	fun2
}

fun2() {
	echo fun2
	is_def1 a && printf 'is_def1? %s '  a || printf 'is_def1? %s '  _
	is_def1 b && printf          '%s '  b || printf          '%s '  _
	is_def1 c && printf          '%s '  c || printf          '%s '  _
	is_def1 d && printf          '%s\n' d || printf          '%s\n' _
	is_def2 a && printf 'is_def2? %s '  a || printf 'is_def2? %s '  _
	is_def2 b && printf          '%s '  b || printf          '%s '  _
	is_def2 c && printf          '%s '  c || printf          '%s '  _
	is_def2 c && printf          '%s\n' d || printf          '%s\n' _
	is_def3 a && printf 'is_def3? %s '  a || printf 'is_def3? %s '  _
	is_def3 b && printf          '%s '  b || printf          '%s '  _
	is_def3 c && printf          '%s '  c || printf          '%s '  _
	is_def3 c && printf          '%s\n' d || printf          '%s\n' _
	fun3
}

fun3() {
	echo fun3
	local a b c
	unset a b c
	is_def1 a && printf 'is_def1? %s '  a || printf 'is_def1? %s '  _
	is_def1 b && printf          '%s '  b || printf          '%s '  _
	is_def1 c && printf          '%s '  c || printf          '%s '  _
	is_def1 d && printf          '%s\n' d || printf          '%s\n' _
	is_def2 a && printf 'is_def2? %s '  a || printf 'is_def2? %s '  _
	is_def2 b && printf          '%s '  b || printf          '%s '  _
	is_def2 c && printf          '%s '  c || printf          '%s '  _
	is_def2 c && printf          '%s\n' d || printf          '%s\n' _
	is_def3 a && printf 'is_def3? %s '  a || printf 'is_def3? %s '  _
	is_def3 b && printf          '%s '  b || printf          '%s '  _
	is_def3 c && printf          '%s '  c || printf          '%s '  _
	is_def3 c && printf          '%s\n' d || printf          '%s\n' _
}


fun1
