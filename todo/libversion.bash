
bash_import ./libcore.bash


__NS__parse_semver() {
	local v=$1
	local regex='^([[:digit:]]+)\.([[:digit:]]+)(\.([0-9\(\)]+))?(-([[:alnum:]]+))?(+([[:alnum:]]+))?$'
	local regex='^'
	regex+='([[:digit:]]+)'      # 1 major number
	regex+='\.([[:digit:]]+)'    # 2 minor number
	regex+='(\.'                 # 3
		regex+='([0-9]+)'        # 4 opt patch number
	regex+=')?'
	regex+='(-'                  # 5
		regex+='([-\.[:alnum:]]+)' # 6 opt pre-release tag
	regex+=')?'
	regex+='(-'                  # 7
		regex+='([-\.[:alnum:]]+)' # 8 opt build tag
	regex+=')?'
	regex+='$'
	if ! [[ $v =~ $regex ]]; then
		return 1
	fi
	local retvar=${retvar:-return}
	# shellcheck disable=SC2016
	[[ ! -R $retvar ]] || die 'Reference not allowed for $retvar'
	local "$retvar" && upvar_array "$retvar" [0]="${BASH_REMATCH[1]:-0}" [1]="${BASH_REMATCH[2]:-0}" [2]="${BASH_REMATCH[4]:-0}" [3]="${BASH_REMATCH[6]}" [4]="${BASH_REMATCH[8]}"
}

__NS__parse_bash_version() {
	local v=$1
	local regex='^'
	regex+='([[:digit:]]+)'      # 1 major number
	regex+='\.([[:digit:]]+)'    # 2 minor number
	regex+='(\.'                 # 3
		regex+='([0-9]+)'        # 4 patch number
		regex+='(\('             # 5
			regex+='([0-9]+)'    # 6 opt build number
		regex+='\))?'            #
	regex+=')?'                  #
	regex+='(-'                  # 7
		regex+='([-[:alnum:]]+)' # 8 opt release status
	regex+=')?'                  #
	regex+='.*$'
	if ! [[ $v =~ $regex ]]; then
		return 1
	fi
	local retvar=${retvar:-return}
	# shellcheck disable=SC2016
	[[ ! -R $retvar ]] || die 'Reference not allowed for $retvar'
	local "$retvar" && upvar_array "$retvar" [0]="${BASH_REMATCH[1]:-0}" [1]="${BASH_REMATCH[2]:-0}" [2]="${BASH_REMATCH[4]:-0}" [3]="${BASH_REMATCH[6]:-0}" [4]="${BASH_REMATCH[8]}"
}

__NS__compare_bash_versions() {
	if (( $# == 1 )); then
		local -n ver1=BASH_VERSINFO
		local -a ver2
		retvar=ver2 __NS__parse_bash_version "${1:?}" || die 'Unable to parse %s' "$1"
	elif (( $# == 2 )); then
		local -a ver1 ver2
		retvar=ver1 __NS__parse_bash_version "${1:?}" || die 'Unable to parse %s' "$1"
		retvar=ver2 __NS__parse_bash_version "${2:?}" || die 'Unable to parse %s' "$2"
	else
		set_exit_code 1
		die 'Missing arguments'
	fi
	#declare -p BASH_VERSINFO ver1 ver2
	local -i i
	for ((i=0; i<4; ++i)); do
		if ((10#${ver1[i]} > 10#${ver2[i]})); then
			return 1
		elif ((10#${ver1[i]} < 10#${ver2[i]})); then
			return 2
		fi
	done
	if [[ ${ver1[4]} > "${ver2[4]}" ]]; then
		return 1
	elif [[ ${ver1[4]} < "${ver2[4]}" ]]; then
		return 2
	fi
	return 0
}

__NS__is_bash_version() {
	local op=$1
	local ver=$2
	local -i exit_code
	__NS__compare_bash_versions "$ver"
	exit_code=$?
	case $op in
		-lt|'<')  (( exit_code == 2                   )) || return 1 ;;
		-le|'<=') (( exit_code == 2 || exit_code == 0 )) || return 1 ;;
		-eq|'=')  ((                   exit_code == 0 )) || return 1 ;;
		-ge|'>=') (( exit_code == 1 || exit_code == 0 )) || return 1 ;;
		-gt|'>')  (( exit_code == 1                   )) || return 1 ;;
		*)
			die 'Invalid operator %s' "$op"
			;;
	esac
	return 0
}

