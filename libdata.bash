# shellcheck disable=SC1090
bash_import "./libipc.bash" __NS__


__NS__open_db() {
	local -n __db="$1"
	: {__db[in]}> /dev/null {__db[out]}> /dev/null
	__NS__mkufifo "${__db[in]}"
	__NS__mkufifo "${__db[out]}"

	if [[ -z ${__db[file]} ]]; then
		__db[file]=default.db
	fi

	if [[ -z ${__db[vfs]} ]]; then
		__db[vfs]=memdb
	fi
	( sqlite3 "${__db[file]}" -batch -line -vfs "${__db[vfs]}" <&"${__db[in]}"  >&"${__db[out]}" ) &
}

__NS__close_db() {
	local -n __db="$1"
	printf '\n%s\n' ".quit" >&"${__db[in]}"
	eval "exec ${__db[in]}>&- ${__db[out]}>&-"
}

__NS__query() {
	local -n __db="$1"
	local sql="$2"
	local line
	local nl=$'\n'
	{
		printf '%s\n' "$sql;"
		printf '%s\n' ".mode list"
		printf '%s\n' "select printf('${nl}EOF');"
		printf '%s\n' ".mode line"
	} >&"${__db[in]}"
	{
		while read -r line ; do
			printf '%s\n' "$line"
			if [[ $line == EOF ]]; then
				break
			fi
		done
	} <&"${__db[out]}"
}

__NS__get_record() {
	local -n __db="$1"
	local sql="$2"
	local prefix="${3:-record_}"
	local field _ value line
	local -i exit_code=1
	local nl=$'\n'
	{
		printf '%s\n' "$sql;"
		printf '%s\n' ".mode list"
		printf '%s\n' "select printf('${nl}EOF');"
		printf '%s\n' ".mode line"
	} >&"${__db[in]}"
	{
		while read -r field _ value; do
			if [[ "${field}${value}" == EOF ]]; then
				return $exit_code
			elif [[ -z "$field" ]]; then
				break
			fi
			exit_code=0
			value="${value//\"/\\\"}"
			value="${value//\$/\\\$}"
			eval "${prefix}${field}=\"${value}\""
		done
		while read -r line; do
			if [[ $line == EOF ]]; then
				break
			fi
		done
		return $exit_code

	}  <&"${__db[out]}"
}

__NS__get_record_map() {
	local -n __db="$1"
	local sql="$2"
	local array_name="${3:-record}"
	local field _ value line
	local -i exit_code=1
	local nl=$'\n'
	{
		printf '%s\n' "$sql;"
		printf '%s\n' ".mode list"
		printf '%s\n' "select printf('${nl}EOF');"
		printf '%s\n' ".mode line"
	} >&"${__db[in]}"
	{
		while read -r field _ value; do
			if [[ "${field}${value}" == EOF ]]; then
				return $exit_code
			elif [[ -z "$field" ]]; then
				break
			fi
			exit_code=0
			value="${value//\"/\\\"}"
			value="${value//\$/\\\$}"
			eval "${array_name}+=( [${field}]=\"${value}\" )"
		done
		while read -r line; do
			if [[ $line == EOF ]]; then
				break
			fi
		done
		return $exit_code

	}  <&"${__db[out]}"
}

__NS__get_records() {
	local -n __db="$1"
	local sql="$2"
	local prefix="${3:-record_}"
	local field _ value
	local nl=$'\n'
	{
		printf '%s\n' "$sql;"
		printf '%s\n' ".mode list"
		printf '%s\n' "select printf('${nl}EOF');"
		printf '%s\n' ".mode line"
	} >&"${__db[in]}"
	{
		while read -r field _ value; do
			if [[ "${field}${value}" == EOF ]]; then
				break
			elif [[ -z $field ]]; then
				continue
			fi
			value="${value//\"/\\\"}"
			value="${value//\$/\\\$}"
			eval "${prefix}${field}+=( \"${value}\" )"
		done
	}  <&"${__db[out]}"
}

__NS__sql_quote() {
	local text="$1"
	local nl="$'\n'"
	text="${text//\'/\'\'}"
	text="${text//$nl/\\n}"
	printf '%s' "'$text'"
}


__NS__parse_record() {
	local prefix="${1:-record_}"
	local field _ value
	while read -r field _ value; do
		if [[ "${field}${value}" == EOF ]]; then
			return 1
		elif [[ -z "$field" ]]; then
			return 0
		fi
		value="${value//\"/\\\"}"
		value="${value//\$/\\\$}"
		eval "${prefix}${field}=\"${value}\""
	done
}


__NS__parse_record_map() {
	local array_name="${1:-record}"
	local field _ value
	while read -r field _ value; do
		if [[ "${field}${value}" == EOF ]]; then
			return 1
		elif [[ -z "$field" ]]; then
			return 0
		fi
		value="${value//\"/\\\"}"
		value="${value//\$/\\\$}"
		eval "${array_name}+=( [${field}]=\"${value}\" )"
	done
}

__NS__iter_record() {
	local -n __db="$1"
	local sql="$2"
	local prefix="${3:-record_}"
	local field _ value line
	local nl=$'\n'
	while :; do
		case "${__db[iter]}" in
		0|'') # init
			{
				printf '%s\n' "$sql;"
				printf '%s\n' ".mode list"
				printf '%s\n' "select printf('${nl}EOF');"
				printf '%s\n' ".mode line"
			} >&"${__db[in]}"
			__db[iter]=1
			continue
			;;
		1) # iterating
			{
				while read -r field _ value; do
					if [[ "${field}${value}" == EOF ]]; then
						unset  "__db[iter]"
						return 1
					fi
					if [[ -z $field ]]; then
						continue
					fi
					while :; do # record found
						value="${value//\"/\\\"}"
						value="${value//\$/\\\$}"
						eval "${prefix}${field}=\"${value}\""
						read -r field _ value
						if [[ -z $field ]]; then
							return 0
						fi
					done
				done
			} <&"${__db[out]}"
			;;
		2) # flush
			{
				while read -r line; do
					if [[ $line == EOF ]]; then
						break
					fi
				done
			} <&"${__db[out]}"
			unset "__db[iter]"
			return 1
			;;
		esac
	done
}

 __NS__flush_iter() {
	local -n __db="$1"
	__db[iter]=2 # flush
 }

