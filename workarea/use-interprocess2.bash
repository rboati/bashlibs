#/bin/bash

source ../libimport.bash
bash_import ../libipc.bash
bash_import ../libdebug.bash


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
mkunamedfifo $fdset
mkunamedfifo $fdget

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