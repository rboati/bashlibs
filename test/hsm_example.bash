#/bin/bash


 source ../libimport.bash
bash_import libhsm.bash
bash_import libdebug.bash


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

state_initial() {
	printf "topState-INIT;"
	FOO=0
	HSM_STATE=s2; return $RET_TRAN
}

state_s() {
	case "$1" in
		$SIG_ENTRY)
			printf "s-ENTRY;"
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf "s-EXIT;"
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf "s-INIT;"
			HSM_STATE=s11; return $RET_TRAN
			;;

		$SIG_E)
			printf "s-E;"
			HSM_STATE=s11; return $RET_TRAN
			;;

		$SIG_I)
			if (( FOO != 0 )); then
				printf "s-I;"
				FOO=0
				return $RET_HANDLED
			fi
			;;

	esac
	HSM_STATE=TOP_STATE; return $RET_PARENT
}

state_s1() {
	case "$1" in
		$SIG_ENTRY)
			printf "s1-ENTRY;"
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf "s1-EXIT;"
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf "s1-INIT;"
			HSM_STATE=s11; return $RET_TRAN
			;;

		$SIG_A)
			printf "s1-A;"
			HSM_STATE=s1; return $RET_TRAN
			;;

		$SIG_B)
			printf "s1-B;"
			HSM_STATE=s11; return $RET_TRAN
			;;

		$SIG_C)
			printf "s1-C;"
			HSM_STATE=s2; return $RET_TRAN
			;;

		$SIG_D)
			choice1 "$@"
			return $?
			;;

		$SIG_F)
			printf "s1-F;"
			HSM_STATE=s211; return $RET_TRAN
			;;

		$SIG_I)
			printf "s1-I;"
			return $RET_HANDLED
			;;

	esac

	HSM_STATE=s; return $RET_PARENT
}

state_s11() {
	case "$1" in
		$SIG_ENTRY)
			printf "s11-ENTRY;"
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf "s11-EXIT;"
			return $RET_HANDLED
			;;

		$SIG_D)
			if (( FOO != 0 )); then
				printf "s11-D;"
				FOO=0
				HSM_STATE=s1; return $RET_TRAN
			fi
			;;

		$SIG_G)
			printf "s11-G;"
			HSM_STATE=s211; return $RET_TRAN
			;;

		$SIG_H)
			printf "s11-H;"
			HSM_STATE=s; return $RET_TRAN
			;;
	esac

	HSM_STATE=s1; return $RET_PARENT
}

state_s2() {
	case "$1" in
		$SIG_ENTRY)
			printf "s2-ENTRY;"
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf "s2-EXIT;"
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf "s2-INIT;"
			HSM_STATE=s211; return $RET_TRAN
			;;

		$SIG_C)
			printf "s2-C;"
			HSM_STATE=s1; return $RET_TRAN
			;;

		$SIG_F)
			printf "s2-F;"
			HSM_STATE=s11; return $RET_TRAN
			;;

		$SIG_I)
			if (( FOO == 0 )); then
				printf "s2-I;"
				FOO=1
				return $RET_HANDLED
			fi
			;;

	esac
	HSM_STATE=s; return $RET_PARENT
}

state_s21() {
	case "$1" in
		$SIG_ENTRY)
			printf "s21-ENTRY;"
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf "s21-EXIT;"
			return $RET_HANDLED
			;;

		$SIG_INIT)
			printf "s21-INIT;"
			HSM_STATE=s211; return $RET_TRAN
			;;

		$SIG_A)
			printf "s21-A;"
			HSM_STATE=s21; return $RET_TRAN
			;;

		$SIG_B)
			printf "s21-B;"
			HSM_STATE=s211; return $RET_TRAN
			;;

		$SIG_G)
			printf "s21-G;"
			HSM_STATE=s1; return $RET_TRAN
			;;
	esac
	HSM_STATE=s2; return $RET_PARENT
}

state_s211() {
	case "$1" in
		$SIG_ENTRY)
			printf "s211-ENTRY;"
			return $RET_HANDLED
			;;

		$SIG_EXIT)
			printf "s211-EXIT;"
			return $RET_HANDLED
			;;

		$SIG_D)
			printf "s211-D;"
			HSM_STATE=s21; return $RET_TRAN
			;;

		$SIG_H)
			printf "s211-H;"
			HSM_STATE=s; return $RET_TRAN
			;;
	esac
	HSM_STATE=s21; return $RET_PARENT
}

choice1() {
	if (( FOO == 0 )); then
		printf "s1-D;"
		FOO=1
		HSM_STATE=s; return $RET_TRAN
	fi
	return $RET_HANDLED
}

send() {
	local SIG=$1
	printf "\n%s:" "${EVENT_NAMES[$SIG]}"
	hsm_dispatch $SIG
}

example_machine() {
	local HSM_STATE      # hsm state
	local -a HSM_PATH=() # hsm path

	local FOO

	hsm_init initial
	send $SIG_A
	send $SIG_B
	send $SIG_D
	send $SIG_E
	send $SIG_I
	send $SIG_F
	send $SIG_I
	send $SIG_I
	send $SIG_F
	send $SIG_A
	send $SIG_B
	send $SIG_D
	send $SIG_D
	send $SIG_E
	send $SIG_G
	send $SIG_H
	send $SIG_H
	send $SIG_C
	send $SIG_G
	send $SIG_C
	send $SIG_C
}



main() {
	set_debugger_property locals.auto 1
	set_debugger_property watch.auto 1
	add_watch '$__EXITCODE__'
	add_watch '$HSM_STATE'
	add_watch '"$HSM_PATH[@]"'
	set_debugger_trap

	example_machine
}

