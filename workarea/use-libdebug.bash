#!/bin/bash

source "../libimport.bash"
DEBUG=2 bash_import "../libloglevel.bash"
bash_import "../libdebug.bash"


set_breakpoint 14
#set_debugger_property color 0
set_debugger_trap

inside_function1 () {
	local LOGDOMAIN="function1"
	"echo$SUFFIX" "echo$SUFFIX" "inside function1"
	"print$SUFFIX" "%s %s" "print$SUFFIX" "inside function1"
	inside_function2
}

inside_function2 () {
	local LOGDOMAIN="function2"
	"echo$SUFFIX" "echo$SUFFIX" "inside function2"
	"print$SUFFIX" "%s %s" "print$SUFFIX" "inside function2"
	inside_function3
}

inside_function3 () {
	# shellcheck disable=SC2034
	local LOGDOMAIN="function3"
	"echo$SUFFIX" "echo$SUFFIX" "inside function3"
	"print$SUFFIX" "%s %s" "print$SUFFIX" "inside function3"
}

declare -i LEVEL MSGLEVEL
SUFFIXES=( "${LOGLEVELS[@],,}" )
unset 'SUFFIXES[0]' # OFF


echo "LOGLEVELS: ${LOGLEVELS[*]}"
for (( LEVEL=0; LEVEL < ${#LOGLEVELS[@]}; ++LEVEL )); do
	set_loglevel $LEVEL

	# shellcheck disable=SC2153
	echo -e "\e[1;37mLOGLEVEL=$LOGLEVEL (${LOGLEVELS[$LOGLEVEL]})\e[0m"
	for MSGLEVEL in "${!SUFFIXES[@]}"; do
		SUFFIX=${SUFFIXES[$MSGLEVEL]}
		echo -e "\e[37mTesting messages at level $MSGLEVEL (${LOGLEVELS[$MSGLEVEL]})\e[0m"
		inside_function1
		"echo$SUFFIX" "echo$SUFFIX" "outside"
		"print$SUFFIX" "%s %s" "print$SUFFIX" "outside"
		# shellcheck disable=SC2012
		ls | LOGDOMAIN='ls' "log$SUFFIX"
	done
	echo
done

for LEVELNAME in "${LOGLEVELS[@]}"; do
	set_loglevel "$LEVELNAME"
	echo -e "\e[1;37mLOGLEVEL=$LOGLEVEL (${LOGLEVELS[$LOGLEVEL]})\e[0m"
	for MSGLEVEL in "${!SUFFIXES[@]}"; do
		SUFFIX=${SUFFIXES[$MSGLEVEL]}
		echo -e "\e[37mTesting messages at level $MSGLEVEL (${LOGLEVELS[$MSGLEVEL]})\e[0m"
		inside_function1
		"echo$SUFFIX" "echo$SUFFIX" "outside"
		"print$SUFFIX" "%s %s" "print$SUFFIX" "outside"
		# shellcheck disable=SC2012
		ls | LOGDOMAIN='ls' "log$SUFFIX"
	done
	echo
done


