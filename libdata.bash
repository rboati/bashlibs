# shellcheck disable=SC1090
bash_import ./libipc.bash -p __NS__ -- mkufifo


__NS__open_db() {
	.require_functions __NS__mkufifo
	local -n __libdata_db="$1"
	: '{__libdata_db[in]}'> /dev/null '{__libdata_db[out]}'> /dev/null
	__NS__mkufifo "${__libdata_db[in]}"
	__NS__mkufifo "${__libdata_db[out]}"

	if [[ -z ${__libdata_db[file]} ]]; then
		__libdata_db[file]=default.db
	fi

	if [[ -z ${__libdata_db[vfs]} ]]; then
		__libdata_db[vfs]=memdb
	fi
	( sqlite3 "${__libdata_db[file]}" -batch -line -vfs "${__libdata_db[vfs]}" <&"${__libdata_db[in]}"  >&"${__libdata_db[out]}" ) &
}

__NS__close_db() {
	 # shellcheck disable=SC2178
	local -n __libdata_db="$1"
	printf '\n%s\n' '.quit' >&"${__libdata_db[in]}"
	eval "exec ${__libdata_db[in]}>&- ${__libdata_db[out]}>&-"
}

__NS__query() {
	 # shellcheck disable=SC2178
	local -n __libdata_db="$1"
	local __libdata_sql="$2"
	local __libdata_line
	local __libdata_nl=$'\n'
	{
		printf '%s\n' "${__libdata_sql};"
		printf '%s\n' '.mode list'
		printf '%s\n' "select printf('${__libdata_nl}EOF');"
		printf '%s\n' '.mode line'
	} >&"${__libdata_db[in]}"
	{
		while read -r __libdata_line ; do
			printf '%s\n' "${__libdata_line}"
			if [[ ${__libdata_line} == EOF ]]; then
				break
			fi
		done
	} <&"${__libdata_db[out]}"
}

__NS__get_record() {
	 # shellcheck disable=SC2178
	local -n __libdata_db="$1"
	local __libdata_sql="$2"
	local __libdata_prefix="${3:-record_}"
	local __libdata_field _ __libdata_value __libdata_line
	local -i __libdata_exit_code=1
	local __libdata_nl=$'\n'
	{
		printf '%s\n' "${__libdata_sql};"
		printf '%s\n' '.mode list'
		printf '%s\n' "select printf('${__libdata_nl}EOF');"
		printf '%s\n' '.mode line'
	} >&"${__libdata_db[in]}"
	{
		while read -r __libdata_field _ __libdata_value; do
			if [[ ${__libdata_field}${__libdata_value} == EOF ]]; then
				return ${__libdata_exit_code}
			elif [[ -z ${__libdata_field} ]]; then
				break
			fi
			__libdata_exit_code=0
			__libdata_value="${__libdata_value//\"/\\\"}"
			__libdata_value="${__libdata_value//\$/\\\$}"
			eval "${__libdata_prefix}${__libdata_field}=\"${__libdata_value}\""
		done
		while read -r __libdata_line; do
			if [[ ${__libdata_line} == EOF ]]; then
				break
			fi
		done
		return ${__libdata_exit_code}

	}  <&"${__libdata_db[out]}"
}

__NS__get_record_map() {
	 # shellcheck disable=SC2178
	local -n __libdata_db="$1"
	local __libdata_sql="$2"
	local __libdata_array_name="${3:-record}"
	local __libdata_field _ __libdata_value __libdata_line
	local -i __libdata_exit_code=1
	local __libdata_nl=$'\n'
	{
		printf '%s\n' "${__libdata_sql};"
		printf '%s\n' '.mode list'
		printf '%s\n' "select printf('${__libdata_nl}EOF');"
		printf '%s\n' '.mode line'
	} >&"${__libdata_db[in]}"
	{
		while read -r __libdata_field _ __libdata_value; do
			if [[ ${__libdata_field}${__libdata_value} == EOF ]]; then
				return ${__libdata_exit_code}
			elif [[ -z ${__libdata_field} ]]; then
				break
			fi
			__libdata_exit_code=0
			__libdata_value="${__libdata_value//\"/\\\"}"
			__libdata_value="${__libdata_value//\$/\\\$}"
			eval "${__libdata_array_name}+=( [${__libdata_field}]=\"${__libdata_value}\" )"
		done
		while read -r __libdata_line; do
			if [[ ${__libdata_line} == EOF ]]; then
				break
			fi
		done
		return ${__libdata_exit_code}

	}  <&"${__libdata_db[out]}"
}

__NS__get_records() {
	 # shellcheck disable=SC2178
	local -n __libdata_db="$1"
	local __libdata_sql="$2"
	local __libdata_prefix="${3:-record_}"
	local __libdata_field _ __libdata_value
	local __libdata_nl=$'\n'
	{
		printf '%s\n' "${__libdata_sql};"
		printf '%s\n' '.mode list'
		printf '%s\n' "select printf('${__libdata_nl}EOF');"
		printf '%s\n' '.mode line'
	} >&"${__libdata_db[in]}"
	{
		while read -r __libdata_field _ __libdata_value; do
			if [[ ${__libdata_field}${__libdata_value} == EOF ]]; then
				break
			elif [[ -z ${__libdata_field} ]]; then
				continue
			fi
			__libdata_value="${__libdata_value//\"/\\\"}"
			__libdata_value="${__libdata_value//\$/\\\$}"
			eval "${__libdata_prefix}${__libdata_field}+=( \"${__libdata_value}\" )"
		done
	}  <&"${__libdata_db[out]}"
}

__NS__sql_quote() {
	local value="$1"
	local nl="$'\n'"
	value="${value//\'/\'\'}"
	value="${value//$nl/\\n}"
	printf '%s' "'${value}'"
}

__NS__escape_nl() {
	local fieldname=$1
	printf "replace(replace(%s,'\\\\','\\\\\\\\'),'\n','\\\\n')" "$fieldname"
}


__NS__parse_record() {
	local prefix="${1:-record_}"
	local field _ value
	while read -r field _ value; do
		if [[ ${field}${value} == EOF ]]; then
			return 1
		elif [[ -z ${field} ]]; then
			return 0
		fi
		value="${value//\"/\\\"}"
		value="${value//\$/\\\$}"
		eval "${prefix}${field}=\"${value}\""
	done
}


__NS__parse_record_map() {
	local __libdata_array_name="${1:-record}"
	local __libdata_field _ __libdata_value
	while read -r __libdata_field _ __libdata_value; do
		if [[ ${__libdata_field}${__libdata_value} == EOF ]]; then
			return 1
		elif [[ -z ${__libdata_field} ]]; then
			return 0
		fi
		__libdata_value="${__libdata_value//\"/\\\"}"
		__libdata_value="${__libdata_value//\$/\\\$}"
		eval "${__libdata_array_name}+=( [${__libdata_field}]=\"${__libdata_value}\" )"
	done
}

__NS__iter_record() {
	 # shellcheck disable=SC2178
	local -n __libdata_db="$1"
	local __libdata_sql="$2"
	local __libdata_prefix="${3:-record_}"
	local __libdata_field _ __libdata_value __libdata_line
	local __libdata_nl=$'\n'
	while :; do
		case "${__libdata_db[iter]}" in
		0|'') # init
			{
				printf '%s\n' "${__libdata_sql};"
				printf '%s\n' '.mode list'
				printf '%s\n' "select printf('${__libdata_nl}EOF');"
				printf '%s\n' '.mode line'
			} >&"${__libdata_db[in]}"
			__libdata_db[iter]=1
			continue
			;;
		1) # iterating
			{
				while read -r __libdata_field _ __libdata_value; do
					if [[ ${__libdata_field}${__libdata_value} == EOF ]]; then
						unset  '__libdata_db[iter]'
						return 1
					fi
					if [[ -z ${__libdata_field} ]]; then
						continue
					fi
					while :; do # record found
						__libdata_value="${__libdata_value//\"/\\\"}"
						__libdata_value="${__libdata_value//\$/\\\$}"
						eval "${__libdata_prefix}${__libdata_field}=\"${__libdata_value}\""
						read -r __libdata_field _ __libdata_value
						if [[ -z ${__libdata_field} ]]; then
							return 0
						fi
					done
				done
			} <&"${__libdata_db[out]}"
			;;
		2) # flush
			{
				while read -r __libdata_line; do
					if [[ ${__libdata_line} == EOF ]]; then
						break
					fi
				done
			} <&"${__libdata_db[out]}"
			unset '__libdata_db[iter]'
			return 1
			;;
		esac
	done
}

 __NS__flush_iter() {
	 # shellcheck disable=SC2178
	local -n __libdata_db="$1"
	__libdata_db[iter]=2 # flush
 }

