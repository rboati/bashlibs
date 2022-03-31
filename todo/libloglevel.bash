
__NS__loglevel_filter_epoch() {
	local prefix=$1
	local IFS='' LC_ALL=C msg
	if (( LOGCOLOR == 1 )); then
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


generate_log_functions() {
	local -i loglevel=${1:-$LOGLEVEL_DEFAULT}
	local -a suffixes=( "${LOGLEVELS[@],,}" )
	unset 'suffixes[0]'
	local -i level fd
	local suffix
	local level_name
	local color reset
	local template

	for (( level=0; level<${#LOGLEVELS[@]}; ++level)); do
		(( fd=100+level ))
		exec {fd}>&-
	done

	if [[ -z $LOGCOLOR ]]; then
		declare -i LOGCOLOR=1
	fi

	if [[ -z $LOGSINK ]]; then
		declare LOGSINK='1>&2'
	fi

	for level in "${!suffixes[@]}"; do
		suffix=${suffixes[$level]}
		level_name="${LOGLEVELS[$level]}"
		(( fd=100+level ))

		if (( LOGCOLOR == 1 )); then
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
				exec ${fd}> >(loglevel_filter "${color}${level_name}${reset}:" $LOGSINK;);

				log${suffix}()   {
					local -ir x=\$?;
					cat > >(logdomain_filter "${color}\$LOGDOMAIN${reset}:" >&${fd};);
					return \$x;
				}
				echo${suffix}()  {
					local -ir x=\$?;
					printf '%b:%s\n' "${color}\$LOGDOMAIN${reset}" "\$*" >&${fd};
					return \$x;
				}
				print${suffix}() {
					local -ir x=\$?; local fmt="\$1"; shift;
					printf "${color}\$LOGDOMAIN${reset}:\$fmt\n" "\$@" >&${fd};
					return \$x;
				}
				EOF
			)
			eval "$template"
		else
			template=$(cat <<- EOF
				log${suffix}()   { declare -ir x=\$?; cat > /dev/null; return \$x; }
				echo${suffix}()  { return \$?; }
				print${suffix}() { return \$?; }
				EOF
			)
		fi
		eval "$template"
	done
}




__NS__setup_logging_1() {
	[[ -z $__NS__LOGLEVEL ]] && __NS__LOGLEVEL=4
	local stdout stderr
	# shellcheck disable=SC2034
	exec {stdout}>&1 {stderr}>&2 # save fd
	LOGSINK="1>&$stderr"
	set_loglevel "$__NS__LOGLEVEL"
	exec >  >(__NS__LOGDOMAIN=stdout loginfo)
	exec 2> >(__NS__LOGDOMAIN=stderr logwarn)
}


__NS__simple_filter() {
	local prefix=$1
	# shellcheck disable=SC1083,SC2140
	eval "
		while read -r msg; do
			printf -- '%s%s%s\n' "\${prefix}" "\$msg"
		done $LOGSINK
	"
}