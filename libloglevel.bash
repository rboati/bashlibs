
declare -ga __NS__LOGLEVELS=( OFF FATAL ERROR WARN INFO DEBUG TRACE )
declare -ga __NS__LOGCOLORS=( 0  '1;31' '31' '33' '34' '37'  '1' )
declare -gi __NS__LOGLEVEL_DEFAULT=3

if [[ -z $__NS__LOGDOMAIN ]]; then
	declare -g __NS__LOGDOMAIN="${BASH_SOURCE[1]##*/}"
fi



__NS__generate_log_functions() {
	declare -a SUFFIXES=( "${__NS__LOGLEVELS[@],,}" )
	unset SUFFIXES[0]
	declare -i LEVEL i
	declare SUFFIX
	declare LEVELNAME
	declare COLOR
	declare -r RESET="\e[0m"
	declare TEMPLATE TEMPLATE_SINK

	if [[ -z $__NS__LOGLEVEL ]]; then
		declare -gi __NS__LOGLEVEL=$__NS__LOGLEVEL_DEFAULT
	fi
	if [[ -z $__NS__LOGCOLOR ]]; then
		declare -i __NS__LOGCOLOR=1
	fi

	if [[ -z $__NS__LOGSINK ]]; then
		declare __NS__LOGSINK='1>&2'
	fi

	for LEVEL in ${!SUFFIXES[@]}; do
		SUFFIX=${SUFFIXES[$LEVEL]}
		LEVELNAME="${__NS__LOGLEVELS[$LEVEL]}"
		COLOR="${__NS__LOGCOLORS[$LEVEL]}"
		if [[ -z $COLOR ]]; then
			COLOR='0'
		fi
		COLOR="\e[${COLOR}m"

		if (( __NS__LOGLEVEL >= LEVEL )); then
			if (( $__NS__LOGCOLOR == 1 )); then
				TEMPLATE_SINK=$(cat <<- EOF
					{
						while IFS='' read -r MSG; do printf '%b:%b:%s\n' "${COLOR}\$__NS__LOGDOMAIN${RESET}" "${COLOR}${LEVELNAME}${RESET}" "\$MSG"; done;
					} $__NS__LOGSINK
					EOF
				)
			else
				TEMPLATE_SINK=$(cat <<- EOF
					{
						while IFS='' read -r MSG; do printf '%s:%s:%s\n' "\$__NS__LOGDOMAIN" "$LEVELNAME" "\$MSG"; done;
					} $__NS__LOGSINK
					EOF
				)
			fi
			TEMPLATE=$(cat <<- EOF
				__NS__log${SUFFIX}()   {
					declare -ir X=\$?; declare MSG;
					$TEMPLATE_SINK;
					return \$X;
				}
				__NS__echo${SUFFIX}()  {
					declare -ir X=\$?; declare MSG;
					printf '%s\n' "\$*" | $TEMPLATE_SINK;
					return \$X;
				}
				__NS__print${SUFFIX}() {
					declare -ir X=\$?; declare MSG; declare FMT="\$1"; shift;
					printf "\$FMT" "\$@" | $TEMPLATE_SINK;
					return \$X;
				}
				EOF
			)
		else
			TEMPLATE=$(cat <<- EOF
				__NS__log${SUFFIX}()   { return \$?; }
				__NS__echo${SUFFIX}()  { return \$?; }
				__NS__print${SUFFIX}() { return \$?; }
				EOF
			)
		fi

		eval "$TEMPLATE"
	done
}

## Example log functions
##
## logXXX functions log as level XXX their stdin
## echoXXX functions log as level XXX, similarly to the "echo" command
## printXXX functions log as level XXX, similarly to the "printf" command
##
  __NS__logfatal() { return $?; }
  __NS__logerror() { return $?; }
   __NS__logwarn() { return $?; }
   __NS__loginfo() { return $?; }
  __NS__logdebug() { return $?; }
  __NS__logtrace() { return $?; }
 __NS__echofatal() { return $?; }
 __NS__echoerror() { return $?; }
  __NS__echowarn() { return $?; }
  __NS__echoinfo() { return $?; }
 __NS__echodebug() { return $?; }
 __NS__echotrace() { return $?; }
__NS__printfatal() { return $?; }
__NS__printerror() { return $?; }
 __NS__printwarn() { return $?; }
 __NS__printinfo() { return $?; }
__NS__printdebug() { return $?; }
__NS__printtrace() { return $?; }


##
## Arguments:
##   {LEVEL} : level number or level name
##
## Globals:
##   LOGLEVEL, LOGLEVEL_DEFAULT, LOGLEVELS, LOGCOLORS
##
## Returns:
##   0 : success
##   1 : underflow, cannot set the requested numeric level; level has been set to the minimum (0)
##   2 : overflow, cannot set the requested numeric level; level has been set to the maximum (6)
##   3 : unknown, cannot set the requested string level; level has been set to the default
##
__NS__set_loglevel() {
	declare LEVEL="$1"
	declare -i i err=0

	if [[ $LEVEL =~ ^[0-9]+$ ]]; then
		if (( LEVEL < 0 )); then
			LEVEL=0
			err=1
		elif (( LEVEL >= ${#__NS__LOGLEVELS[@]} )); then
			LEVEL=$(( ${#__NS__LOGLEVELS[@]} - 1 ))
			err=2
		fi
	else
		while : ; do
			for (( i=0; i< ${#__NS__LOGLEVELS[@]}; ++i )); do
				if [[ $LEVEL == ${__NS__LOGLEVELS[$i]} ]]; then
					LEVEL=$i
					break 2
				fi
			done
			LEVEL=$__NS__LOGLEVEL_DEFAULT
			err=3
			break
		done
	fi
	__NS__LOGLEVEL=$LEVEL __NS__generate_log_functions
	return $err
}

__NS__generate_log_functions


