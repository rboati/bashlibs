
mkpipe() {
	local -i fdin="$1"
	local -i fdout="$2"
	local e
	local -i pidout pidin
	# shellcheck disable=SC2155
	local pipe="$(
		(
			exec 0</dev/null 1</dev/null
			{
				(
					echo "pidout='$BASHPID'" >&2;
					exec tail -f /dev/null 2> /dev/null
				) | (
					echo "pidin='$BASHPID'" >&2;
					exec tail -f /dev/null 2> /dev/null
				)
			} &
		) 2>&1 | for (( i=0; i < 2; ++i )); do
			read -r e
			printf '%s\n' "$e"
		done
	)"
	eval "$pipe"
	eval "exec $fdout> /proc/${pidout}/fd/1 $fdin< /proc/${pidin}/fd/0"
	kill "$pidout" "$pidin"
}


mkufifo() {
	local -i fd="$1"
	# shellcheck disable=SC2155
	local pipe="$(mktemp -u)"
	mkfifo "$pipe"
	eval "exec $fd<>'$pipe'"
	rm "$pipe"
}

