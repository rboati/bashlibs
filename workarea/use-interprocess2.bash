#!/bin/bash

# shellcheck disable=SC1091
source ../bashlibs.bash
bash_import ../libipc.bash mkufifo
#bash_import ../libdebug.bash


storage() {
	local -i fdset="$1"
	local -i fdget="$2"
	local state="set" line
	local -a store
	while :; do
		case "$state" in
			set)
				store=()
				while read -u $fdset -r line; do
					[[ $line == $'\04' ]] && break;
					echo "storage set: $line" 2>&1
					store+=( "$line" )
				done
				echo "storage set finished!" 2>&1
				state="get"
				;;
			get)
				{
					printf '%s\n' "${store[@]^^}"
					printf $'\04\n'
				} >&$fdget
				state="set"
				;;
		esac
		(( i++ == 4 )) && break
	done
}

: {fdset}<>/dev/null {fdget}<>/dev/null
mkufifo $fdset
mkufifo $fdget

(storage $fdset $fdget) &

{
	printf 'hello\n'
	printf 'world\n'
	printf $'\04\n'
} >&$fdset


declare MSG="" LINE
while read -u $fdget -r LINE; do
	[[ $LINE == $'\04' ]] && break;
	MSG+="$LINE"
done

echo "MSG='$MSG'"

{
	printf 'hello\n'
	printf 'another\n'
	printf 'world\n'
	printf $'\04\n'
} >&$fdset

wait


#With local -n (bash 4.3) we get the full power of everything:
#	{var[sub]}<file
#which can be done as well as:
#	x() {
#		local -n a="$1" b="$2" c="$3"
#		exec {a}<&0 {b}>&1 {c}>&2;
#	}
# then
#	declare -A A;
#	x "A[t1]" "A[t2]" "A[t3]"
#but it can even do something like {!var}<file which isn't in bash:
#	x=a1 y=a2 z=a3;
#	x "$x" "$y" "$z"
