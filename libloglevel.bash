
declare -ga __NS__LOGLEVELS=( OFF FATAL ERROR WARN INFO DEBUG TRACE )
declare -ga __NS__LOGCOLORS=( 0  '1;31' '31' '33' '34' '37'  '1' )
declare -gi __NS__LOGLEVEL_DEFAULT=3

if [[ -z $__NS__LOGDOMAIN ]]; then
	declare -g __NS__LOGDOMAIN="${BASH_SOURCE[1]##*/}"
fi



__NS__logdomain_filter() {
	local prefix="$1"
	local IFS='' LC_ALL=C msg
	eval "
	while read -r msg; do
		printf -- '$prefix%s\n' \"\$msg\"
	done
	"
}

__NS__loglevel_filter() {
	local prefix="$1"
	local IFS='' LC_ALL=C msg
	eval "
	while read -r msg; do
		printf -- '$prefix%s\n' \"\$msg\"
	done
	"
}

__NS__loglevel_filter_epoch() {
	local prefix="$1"
	local IFS='' LC_ALL=C msg
	if (( __NS__LOGCOLOR == 1 )); then
		eval "
		while read -r msg; do
			printf -- '\e[2m[%s]\e[0m$prefix%s\n' \"\$EPOCHREALTIME\" \"\$msg\"
		done
		"
	else
		eval "
		while read -r msg; do
			printf -- '[%s]$prefix%s\n' \"\$EPOCHREALTIME\" \"\$msg\"
		done
		"
	fi
}


__NS__generate_log_functions() {
	local -i loglevel="${1:-$__NS__LOGLEVEL_DEFAULT}"
	local -a suffixes=( "${__NS__LOGLEVELS[@],,}" )
	unset 'suffixes[0]'
	local -i level fd
	local suffix
	local level_name
	local color reset
	local template

	for (( level=0; level<${#__NS__LOGLEVELS[@]}; ++level)); do
		(( fd=100+level ))
		exec {fd}>&-
	done

	if [[ -z $__NS__LOGCOLOR ]]; then
		declare -i __NS__LOGCOLOR=1
	fi

	if [[ -z $__NS__LOGSINK ]]; then
		declare __NS__LOGSINK='1>&2'
	fi

	for level in "${!suffixes[@]}"; do
		suffix=${suffixes[$level]}
		level_name="${__NS__LOGLEVELS[$level]}"
		(( fd=100+level ))

		if (( __NS__LOGCOLOR == 1 )); then
			color="${__NS__LOGCOLORS[$level]}"
			[[ -z $color ]] && color='0'
			color="\e[${color}m"
			reset="\e[0m"
		else
			color=''
			reset=''
		fi

		if (( loglevel >= level )); then
			template=$(cat <<- EOF
				exec ${fd}>&2;
				exec ${fd}> >(__NS__loglevel_filter "${color}${level_name}${reset}:" $__NS__LOGSINK;);

				__NS__log${suffix}()   {
					local -ir x=\$?;
					cat > >(__NS__logdomain_filter "${color}\$__NS__LOGDOMAIN${reset}:" >&${fd};);
					return \$x;
				}
				__NS__echo${suffix}()  {
					local -ir x=\$?;
					printf '%b:%s\n' "${color}\$__NS__LOGDOMAIN${reset}" "\$*" >&${fd};
					return \$x;
				}
				__NS__print${suffix}() {
					local -ir x=\$?; local fmt="\$1"; shift;
					printf "${color}\$__NS__LOGDOMAIN${reset}:\$fmt\n" "\$@" >&${fd};
					return \$x;
				}
				EOF
			)
			eval "$template"
		else
			template=$(cat <<- EOF
				__NS__log${suffix}()   { declare -ir x=\$?; cat > /dev/null; return \$x; }
				__NS__echo${suffix}()  { return \$?; }
				__NS__print${suffix}() { return \$?; }
				EOF
			)
		fi
		eval "$template"
		# shellcheck disable=SC2034
		declare -gi __NS__LOGLEVEL="$loglevel"
	done
}




## Example log functions
##
## logXXX functions log as level XXX their stdin
## echoXXX functions log as level XXX, similarly to the "echo" command
## printXXX functions log as level XXX, similarly to the "printf" command
##
  __NS__logfatal() { declare -ir x=$?; cat > /dev/null; return $x; }
  __NS__logerror() { declare -ir x=$?; cat > /dev/null; return $x; }
   __NS__logwarn() { declare -ir x=$?; cat > /dev/null; return $x; }
   __NS__loginfo() { declare -ir x=$?; cat > /dev/null; return $x; }
  __NS__logdebug() { declare -ir x=$?; cat > /dev/null; return $x; }
  __NS__logtrace() { declare -ir x=$?; cat > /dev/null; return $x; }
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
##   {level} : level number or level name
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
	declare level="$1"
	declare -i i err=0

	if [[ $level =~ ^[0-9]+$ ]]; then
		if (( level < 0 )); then
			level=0
			err=1
		elif (( level >= ${#__NS__LOGLEVELS[@]} )); then
			level=$(( ${#__NS__LOGLEVELS[@]} - 1 ))
			err=2
		fi
	else
		while : ; do
			for (( i=0; i< ${#__NS__LOGLEVELS[@]}; ++i )); do
				if [[ ${level,,} == "${__NS__LOGLEVELS[$i],,}" ]]; then
					level=$i
					break 2
				fi
			done
			level=$__NS__LOGLEVEL_DEFAULT
			err=3
			break
		done
	fi
	__NS__generate_log_functions $level
	return $err
}

__NS__setup_logging_1() {
	[[ -z $__NS__LOGLEVEL ]] && __NS__LOGLEVEL=4
	local stdout stderr
	exec {stdout}>&1 {stderr}>&2 # save fd
	# shellcheck disable=SC2034
	__NS__LOGSINK="1>&$stderr"
	set_loglevel "$__NS__LOGLEVEL"
	exec >  >(__NS__LOGDOMAIN=stdout loginfo)
	exec 2> >(__NS__LOGDOMAIN=stderr logwarn)
}


__NS__setup_logging_2() {
	[[ -z $LOGLEVEL ]] && LOGLEVEL=4
	local stdout stderr
	exec {stdout}>&1 {stderr}>&2 # save fd
	# shellcheck disable=SC2034
	__NS__LOGSINK="1>&$stderr"
	set_loglevel "$LOGLEVEL"
	exec >  >(__NS__LOGDOMAIN=stdout loginfo)
	exec 2> >(__NS__LOGDOMAIN=stderr logwarn)
}


__NS__simple_filter() {
	local prefix=$1
	eval "
		while read -r msg; do
			printf -- '%s%s%s\n' "\${prefix}" "\$msg"
		done $__NS__LOGSINK
	"
}

# exec ${fd}> >(__NS__loglevel_filter "${color}${level_name}${reset}:" $__NS__LOGSINK;);
# __NS__log${suffix}()   {
# 	declare -ir x=\$?;
# 	local color reset
# 	if (( __NS__LOGCOLOR == 1 )); then
# 		color="${__NS__LOGCOLORS[$level]}"
# 		[[ -z $color ]] && color='0'
# 		color="\e[${color}m"
# 		reset="\e[0m"
# 	else
# 		color=''
# 		reset=''
# 	fi

# 	cat | __NS__simple_filter "${color}${level_name}${reset}:${color}${__NS__LOGDOMAIN}${reset}:"
# 	return \$x;
# }
# __NS__echo${suffix}()  {
# 	declare -ir X=\$?; declare msg;
# 	printf '%b:%s\n' "${color}\$__NS__LOGDOMAIN${reset}" "\$*" >&${fd};
# 	return \$X;
# }
# __NS__print${suffix}() {
# 	declare -ir X=\$?; declare msg; declare FMT="\$1"; shift;
# 	printf "${color}\$__NS__LOGDOMAIN${reset}:\$FMT\n" "\$@" >&${fd};
# 	return \$X;
# }