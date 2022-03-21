#!/bin/bash

set -u

# not compliant with "nounset"
fun1() {
	if [[ -z $1 ]]; then
		echo "Missing parameter"
		return 1
	fi
	echo "$1"
}

# compliant
fun2() {
	if [[ -z ${1:-} ]]; then
		echo "Missing parameter"
		return 1
	fi
	echo "$1"
}

# not compliant with "nounset"
# declaration is not enough
fun3() {
	local var
	echo "$var"
}



#fun1 "$@"
#fun2 "$@"
fun3