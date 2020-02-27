#/bin/bash

source "../libimport.bash"
bash_import "../libloglevel.bash"

inside_function1 () {
	local LOGDOMAIN="function1"
	"echo$SUFFIX" "echo$SUFFIX" "inside function1"
	"print$SUFFIX" "%s %s" "print$SUFFIX" "inside function1" 1 2 3 4 5
	inside_function2
}

inside_function2 () {
	local LOGDOMAIN="function2"
	"echo$SUFFIX" "echo$SUFFIX" "inside function2"
	"print$SUFFIX" "%s %s" "print$SUFFIX" "inside function2" 1 2 3 4 5
	inside_function3
}

inside_function3 () {
	local LOGDOMAIN="function3"
	"echo$SUFFIX" "echo$SUFFIX" "inside function3"
	"print$SUFFIX" "%s %s" "print$SUFFIX" "inside function3" 1 2 3 4 5
}

declare -i LEVEL MSGLEVEL
SUFFIXES=( "${LOGLEVELS[@],,}" )
unset SUFFIXES[0] # OFF

echo
echo "Setting LOGLEVEL by number"
echo

echo LOGLEVELS: ${LOGLEVELS[@]}
for (( LEVEL=0; LEVEL < ${#LOGLEVELS[@]}; ++LEVEL )); do
	set_loglevel $LEVEL

	echo -e "\e[1;37mLOGLEVEL=$LOGLEVEL (${LOGLEVELS[$LOGLEVEL]})\e[0m"
	for MSGLEVEL in "${!SUFFIXES[@]}"; do
		SUFFIX=${SUFFIXES[$MSGLEVEL]}
		echo -e "\e[37mTesting messages at level $MSGLEVEL (${LOGLEVELS[$MSGLEVEL]})\e[0m"
		inside_function1
		"echo$SUFFIX" "echo$SUFFIX" "outside"
		"print$SUFFIX" "%s %s" "print$SUFFIX" "outside"
		ls  | LOGDOMAIN=ls log$SUFFIX
	done
	echo
done

echo
echo "Setting LOGLEVEL by name"
echo

for LEVELNAME in "${LOGLEVELS[@]}"; do
	set_loglevel $LEVELNAME
	echo -e "\e[1;37mLOGLEVEL=$LOGLEVEL (${LOGLEVELS[$LOGLEVEL]})\e[0m"
	for MSGLEVEL in "${!SUFFIXES[@]}"; do
		SUFFIX=${SUFFIXES[$MSGLEVEL]}
		echo -e "\e[37mTesting messages at level $MSGLEVEL (${LOGLEVELS[$MSGLEVEL]})\e[0m"
		inside_function1
		"echo$SUFFIX" "echo$SUFFIX" "outside"
		"print$SUFFIX" "%s %s" "print$SUFFIX" "outside"
		ls | LOGDOMAIN=ls log$SUFFIX
	done
	echo
done


