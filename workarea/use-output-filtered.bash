#!/bin/bash


output_filter() {
	local -i i=0
	local PREFIX="${1:-PREFIX}" MSG
	while IFS='' read -r MSG; do
		printf '%b(%d): %s\n' "$PREFIX" $((i++)) "$MSG"
	done
}

shopt -s lastpipe

exec 10<&0 11>&1 12>&2 # save stdin, stdout, stderr
exec > >(output_filter MAIN)
exec 20<&0 21>&1 22>&2 # save stdin, stdout, stderr


A=UNCHANGED

{
	# Unfiltered is executed in current shell
	A=CHANGED
	echo "Lorem ipsum (filtered)"
	echo "Lorem ipsum (unfiltered)" >&11
	echo "Lorem ipsum (unfiltered by sub filter)" >&21
}

echo A is $A
A=UNCHANGED

{
	# all code blocks in a pipe are executed in a subshell!
	# Assignment are lost!
	A=CHANGED
	echo "Lorem ipsum (filtered)"
	echo "Lorem ipsum (unfiltered)" >&11
	echo "Lorem ipsum (unfiltered by sub filter)" >&21
} | output_filter SUB1

echo A is $A
A=UNCHANGED

{
	# code blocks with redirection instead are executed in current shell
	# but the output stream is not syncronous!
	A=CHANGED
	echo "Lorem ipsum (filtered)"
	echo "Lorem ipsum (unfiltered)" >&11
	echo "Lorem ipsum (unfiltered by sub filter)" >&21
} > >(output_filter SUB2)

echo A is $A


exec <&10 >&11 >&12 # set stdin, stdout, stderr
