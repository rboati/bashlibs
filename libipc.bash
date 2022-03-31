
__NS__mkpipe() {
	pragma required_commands /usr/bin/tail
	local -i fdin=${1:?}
	local -i fdout=${2:?}
	local -i pidout pidin
	local IFS=$' \t\n'
	# shellcheck disable=SC2155
	local pipe="$(
		(
			local -i i
			local line
			exec 0</dev/null 1</dev/null
			{
				(
					echo "pidout='$BASHPID'" >&2;
					exec /usr/bin/tail -f /dev/null 2> /dev/null
				) | (
					echo "pidin='$BASHPID'" >&2;
					exec /usr/bin/tail -f /dev/null 2> /dev/null
				)
			} &
		) 2>&1 | for (( i=0; i < 2; ++i )); do
			read -r line
			printf '%s\n' "$line"
		done
	)"
	eval "$pipe"
	eval "exec $fdout> /proc/${pidout}/fd/1 $fdin< /proc/${pidin}/fd/0"
	kill "$pidout" "$pidin"
}


__NS__mkufifo() {
	pragma required_commands /usr/bin/mkfifo /bin/mktemp /bin/rm
	local -i fd=$1
	# shellcheck disable=SC2155
	local pipe="$(/bin/mktemp -u)"
	/usr/bin/mkfifo "$pipe"
	eval "exec $fd<>'$pipe'"
	/bin/rm "$pipe"
}

