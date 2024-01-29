#!/bin/bash

# shellcheck disable=SC1091
source ../bashlibs.bash
#set_loglevel trace

bash_import ../libhsm.bash


initialize_libhsm


declare -gri SIG_A=0
declare -gri SIG_B=1
declare -gri SIG_C=2
declare -gri SIG_D=3
declare -gri SIG_E=4
declare -gri SIG_F=5
declare -gri SIG_G=6
declare -gri SIG_H=7
declare -gri SIG_I=8
declare -gra EVENT_NAMES=( A B C D E F G H I )

# Initial pseudo state
# It receives only INIT events
state_initial() {
	printf 'topState-INIT;'
	x_FOO=0
	STATE=s2 && return $RET_TRAN
}

state_s() {
	case "$1" in
		$SIG_ENTRY)
			printf 's-ENTRY;'
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf 's-EXIT;'
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf 's-INIT;'
			STATE=s11 && return $RET_TRAN
			;;

		$SIG_E)
			printf 's-E;'
			STATE=s11 && return $RET_TRAN
			;;

		$SIG_I)
			if (( x_FOO != 0 )); then
				printf 's-I;'
				x_FOO=0
				return $RET_HANDLED
			fi
			;;

	esac
	STATE=TOP_STATE && return $RET_PARENT
}

state_s1() {
	case "$1" in
		$SIG_ENTRY)
			printf 's1-ENTRY;'
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf 's1-EXIT;'
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf 's1-INIT;'
			STATE=s11 && return $RET_TRAN
			;;

		$SIG_A)
			printf 's1-A;'
			STATE=s1 && return $RET_TRAN
			;;

		$SIG_B)
			printf 's1-B;'
			STATE=s11 && return $RET_TRAN
			;;

		$SIG_C)
			printf 's1-C;'
			STATE=s2 && return $RET_TRAN
			;;

		$SIG_D)
			choice1 "$@"
			return $?
			;;

		$SIG_F)
			printf 's1-F;'
			STATE=s211 && return $RET_TRAN
			;;

		$SIG_I)
			printf 's1-I;'
			return $RET_HANDLED
			;;

	esac

	STATE=s && return $RET_PARENT
}

state_s11() {
	case "$1" in
		$SIG_ENTRY)
			printf 's11-ENTRY;'
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf 's11-EXIT;'
			return $RET_HANDLED
			;;

		$SIG_D)
			if (( x_FOO != 0 )); then
				printf 's11-D;'
				x_FOO=0
				STATE=s1 && return $RET_TRAN
			fi
			;;

		$SIG_G)
			printf 's11-G;'
			STATE=s211 && return $RET_TRAN
			;;

		$SIG_H)
			printf 's11-H;'
			STATE=s && return $RET_TRAN
			;;
	esac

	STATE=s1 && return $RET_PARENT
}

state_s2() {
	case "$1" in
		$SIG_ENTRY)
			printf 's2-ENTRY;'
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf 's2-EXIT;'
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf 's2-INIT;'
			STATE=s211 && return $RET_TRAN
			;;

		$SIG_C)
			printf 's2-C;'
			STATE=s1 && return $RET_TRAN
			;;

		$SIG_F)
			printf 's2-F;'
			STATE=s11 && return $RET_TRAN
			;;

		$SIG_I)
			if (( x_FOO == 0 )); then
				printf 's2-I;'
				x_FOO=1
				return $RET_HANDLED
			fi
			;;

	esac
	STATE=s && return $RET_PARENT
}

state_s21() {
	case "$1" in
		$SIG_ENTRY)
			printf 's21-ENTRY;'
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf 's21-EXIT;'
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf 's21-INIT;'
			STATE=s211 && return $RET_TRAN
			;;

		$SIG_A)
			printf 's21-A;'
			STATE=s21 && return $RET_TRAN
			;;

		$SIG_B)
			printf 's21-B;'
			STATE=s211 && return $RET_TRAN
			;;

		$SIG_G)
			printf 's21-G;'
			STATE=s1 && return $RET_TRAN
			;;
	esac
	STATE=s2 && return $RET_PARENT
}

state_s211() {
	case "$1" in
		$SIG_ENTRY)
			printf 's211-ENTRY;'
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf 's211-EXIT;'
			return $RET_HANDLED
			;;

		$SIG_D)
			printf 's211-D;'
			STATE=s21 && return $RET_TRAN
			;;

		$SIG_H)
			printf 's211-H;'
			STATE=s && return $RET_TRAN
			;;
	esac
	STATE=s21 && return $RET_PARENT
}

# Choice pseudo state
choice1() {
	if (( x_FOO == 0 )); then
		printf 's1-D;'
		x_FOO=1
		STATE=s && return $RET_TRAN
	fi
	return $RET_HANDLED
}

dispatch() {
	local -i sig=$1
	printf '\n%s:' "${EVENT_NAMES[sig]}"
	dispatch_event $sig
}

example_machine() {
	local STATE      # hsm state
	local -a HSM_PATH=() # hsm path

	local x_FOO=0

	start_initial_state initial
	dispatch $SIG_A
	dispatch $SIG_B
	dispatch $SIG_D
	dispatch $SIG_E
	dispatch $SIG_I
	dispatch $SIG_F
	dispatch $SIG_I
	dispatch $SIG_I
	dispatch $SIG_F
	dispatch $SIG_A
	dispatch $SIG_B
	dispatch $SIG_D
	dispatch $SIG_D
	dispatch $SIG_E
	dispatch $SIG_G
	dispatch $SIG_H
	dispatch $SIG_H
	dispatch $SIG_C
	dispatch $SIG_G
	dispatch $SIG_C
	dispatch $SIG_C
}


example_machine

