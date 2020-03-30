#!/bin/bash

# shellcheck disable=SC1091
source ../libimport.bash
bash_import ../libipc.bash

exec 11>&1


log() {
	printf '%5s: %-5s %s\n' "$1" "$2" "${3:+($3)}">&11
}

plural() {
	local -i n="$1"
	local singular="$2"
	local plural="${3:-${singular}s}"
	if (( n == 1 )); then
		echo -n "$n $singular"
	else
		echo -n "$n $plural"
	fi
}

send() {
	echo "$@"
}

player() {
	local player="$1"
	local msg answer
	local -i win=5 diff=2
	local -i mypoints=0 hispoints=0 delta
	local -i mysaves=0 mysmashes=0 mymatchpoints=0 matchpoints
	while read -r msg; do
		case "$msg" in
			ping)
				if (( RANDOM % 5 == 0 )); then
					(( ++mysmashes ))
					answer="smash"
					log "$player" "$answer" "Take that!"
				else
					answer="ping"
					log "$player" "$answer"
				fi
				send "$answer"
				;;
			pong)
				if (( RANDOM % 3 == 0 )); then
					(( ++mysmashes ))
					answer="smash"
					log "$player" "$answer" "Too easy, take that!"
				else
					answer="ping"
					log "$player" "$answer"
				fi
				send "$answer"
				;;
			serve)
				if (( RANDOM % 2 == 0 )); then
					answer="ping"
				else
					answer="pong"
				fi
				log "$player" "$answer"
				send "$answer"
				;;
			smash)
				if (( RANDOM % 3 == 0 )); then
					answer="miss"
					(( ++hispoints ))
					if (( hispoints >= win && (((delta=hispoints-mypoints)>0)?delta:-delta) >= diff )); then
						answer="miss"
						log "$player" "lost" "I lost! Final score is $mypoints to $hispoints, I had $(plural $mymatchpoints matchpoint), I made $(plural $mysaves save) and I smashed $(plural $mysmashes time)"
						send "$answer"
						exit 1
					fi
					if ((mypoints > hispoints && mypoints >= (win-1) && mypoints >= 4 )); then
						(( ++mymatchpoints ))
					fi
					log "$player" "miss" "Ouch!"
				else
					(( ++mysaves ))
					answer="pong"
					log "$player" "pong" "Whew!"
				fi
				send "$answer"
				;;
			miss)
				(( ++mypoints ))
				if (( mypoints >= win && (((delta=hispoints-mypoints)>0)?delta:-delta) >= diff )); then
					log "$player" "won" "I won! Final score is $mypoints to $hispoints, I had $(plural $mymatchpoints matchpoint), I made $(plural $mysaves save) and I smashed $(plural $mysmashes time)"
					exit 0
				fi
				answer="serve"
				if ((mypoints > hispoints && mypoints >= (win-1) && mypoints >= 4 )); then
					(( ++mymatchpoints ))
					(( matchpoints=mypoints-hispoints ))
					log "$player" "serve" "Score is $mypoints to $hispoints, I have $(plural $matchpoints matchpoint)!"
				elif ((mypoints < hispoints && hispoints >= (win-1) && hispoints >= 4 )); then
					(( matchpoints=hispoints-mypoints ))
					log "$player" "serve" "Score is $mypoints to $hispoints, You have $(plural $matchpoints matchpoint)!"
				else
					log "$player" "serve" "Score is $mypoints to $hispoints"
				fi
				sleep 1
				send "$answer"
				;;
			quit)
				exit 0
				;;
			*)
				log "$player" "@*#!" "What did you say?"
				exit 2
				;;
		esac
		#sleep $( (((RANDOM % 2) == 0)) && echo "0.5" || echo "1" )
		sleep 0.$((RANDOM % 10))
	done
}




IPC_TYPE=pipe

case "$IPC_TYPE" in
fifo)
	mkfifo player1.fifo player2.fifo
	trap 'echo quit > player1.fifo; echo quit > player2.fifo' SIGINT
	( player Bob < player2.fifo > player1.fifo ) &
	( player Karl < player1.fifo > player2.fifo ) &
	echo "serve" > player1.fifo
	wait
	rm -r player1.fifo player2.fifo
	;;
unnamedfifo)
	: {fd1}> /dev/null
	mkunamedfifo $fd1
	: {fd2}> /dev/null
	mkunamedfifo $fd2

	trap 'echo quit >&$fd1; echo quit >&$fd2; eval "exec $fd1>&- $fd2>&-"' SIGINT
	( player Bob <&$fd2  >&$fd1 ) &
	( player Karl <&$fd1 >&$fd2 ) &
	echo "serve" >&$fd1
	wait
	;;
pipe)

	mkpipe $fdin1 $fdout1: {fdin1}> /dev/null {fdout1}> /dev/null
	: {fdin2}> /dev/null {fdout2}> /dev/null
	mkpipe $fdin2 $fdout2

	trap 'echo quit >&$fdout1; echo quit >&$fdout2; eval "exec $fdin1<&- $fdout1>&- $fdin2<&- $fdout2>&-"' SIGINT
	( player Bob <& $fdin2  >& $fdout1 ) &
	( player Karl <& $fdin1 >& $fdout2 ) &

	echo "serve" >&$fdout1
	wait
	;;
esac