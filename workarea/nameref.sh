#!/bin/bash

fun1() {
	local a=0
	local -n b=a
	local c=a
	fun2
	echo "fun1"
	declare -p a b c
	echo "b = $b"
	echo "c = ${!c}"
}

fun2() {
	local a=1
	echo "fun2"
	declare -p a b
	echo "b = $b"
	echo "c = ${!c}"
}

# trying namerefs...
fun1

