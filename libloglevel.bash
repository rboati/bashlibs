
declare -ga __NS__LOGLEVELS=( OFF FATAL ERROR WARN INFO DEBUG TRACE )
declare -ga __NS__LOGCOLORS=( 0  '1;31' '31' '33' '34' '37'  '1' )
declare -gi __NS__LOGLEVEL_DEFAULT=3

if [[ -z $__NS__LOGDOMAIN ]]; then
	declare -g __NS__LOGDOMAIN="${BASH_SOURCE[1]##*/}"
fi



__NS__logdomain_filter() {
	local prefix="$1"
	local IFS='' msg
	while read -r msg; do
		printf '%b%s\n' "$prefix" "$msg"
	done
}

__NS__loglevel_filter() {
	local prefix="$1"
	local IFS='' msg
	while read -r msg; do
		printf '%b%s\n' "$prefix" "$msg"
	done
}


__NS__generate_log_functions() {
	local -i loglevel="${1:-$__NS__LOGLEVEL_DEFAULT}"
	local -a suffixes=( "${__NS__LOGLEVELS[@],,}" )
	unset suffixes[0]
	local -i level fd
	local suffix
	local level_name
	local color reset
	local template

	for (( level=0; level<${#__NS__LOGLEVELS[@]}; ++level)); do
		let fd=100+level
		eval "exec ${fd}>&-"
	done

	if [[ -z $__NS__LOGCOLOR ]]; then
		declare -i __NS__LOGCOLOR=1
	fi

	if [[ -z $__NS__LOGSINK ]]; then
		declare __NS__LOGSINK='1>&2'
	fi

	for level in ${!suffixes[@]}; do
		suffix=${suffixes[$level]}
		level_name="${__NS__LOGLEVELS[$level]}"
		let fd=100+level

		if (( $__NS__LOGCOLOR == 1 )); then
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
					declare -ir X=\$?;
					cat > >(__NS__logdomain_filter "${color}\$__NS__LOGDOMAIN${reset}:" >&${fd};);
					return \$X;
				}
				__NS__echo${suffix}()  {
					declare -ir X=\$?; declare msg;
					printf '%b:%s\n' "${color}\$__NS__LOGDOMAIN${reset}" "\$*" >&${fd};
					return \$X;
				}
				__NS__print${suffix}() {
					declare -ir X=\$?; declare msg; declare FMT="\$1"; shift;
					printf "${color}\$__NS__LOGDOMAIN${reset}:\$FMT\n" "\$@" >&${fd};
					return \$X;
				}
				EOF
			)
			eval "$template"
			template+=$(cat <<- EOF
				EOF
			)
		else
			template=$(cat <<- EOF
				__NS__log${suffix}()   { declare -ir X=\$?; cat > /dev/null; return \$X; }
				__NS__echo${suffix}()  { return \$?; }
				__NS__print${suffix}() { return \$?; }
				EOF
			)
		fi
		eval "$template"
		declare -gi __NS__LOGLEVEL="$loglevel"
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



