# shellcheck disable=SC1090
bash_import ./libipc.bash -p __NS__ipc_ mkufifo


# $1: Var name of db connection descriptor
__NS__open() {
	pragma require_functions __NS__mkufifo
	pragma local_prefix x_
	 # shellcheck disable=SC2178
	local -n x_db=$1
	if [[ -n  ${x_db[in]} && -n ${x_db[out]} ]]; then
		printerror 'Database is not closed'
		return 1
	fi
	# shellcheck disable=SC2093,SC1083
	exec {x_db[in]}<>/dev/null {x_db[out]}<>/dev/null
	__NS__ipc_mkufifo "${x_db[in]}"
	__NS__ipc_mkufifo "${x_db[out]}"

	if [[ -z ${x_db[file]} ]]; then
		x_db[file]='default.db'
	fi

	if [[ -z ${x_db[vfs]} ]]; then
		x_db[vfs]=memdb
	fi
	( exec sqlite3 "${x_db[file]}" -batch -line -vfs "${x_db[vfs]}" <&${x_db[in]}  >&${x_db[out]} ) &
}

# $1: Var name of db connection descriptor
__NS__close() {
	pragma local_prefix x_
	 # shellcheck disable=SC2178
	local -n x_db=$1
	 # shellcheck disable=SC2154
	if (( x_db[iter] == 1 )); then
		__NS__flush "${!x_db}"
	fi
	# shellcheck disable=SC2086
	printf '\n%s\n' '.quit' >&${x_db[in]}
	#eval "exec ${x_db[in]}>&- ${x_db[out]}>&-"
	#: ${x_db[in]}>&- ${x_db[out]}<&-
	unset -v 'x_db[in]' 'x_db[out]'
}


# $1: Var name of db connection descriptor
# $2: Query SQL
__NS__query() {
	pragma local_prefix x_
	 # shellcheck disable=SC2178
	local -n x_db=$1
	if [[ -z  ${x_db[in]} || -z ${x_db[out]} ]]; then
		printerror 'Database connection is closed'
		return 1
	fi

	if (( x_db[iter] == 1 )); then
		__NS__flush "${!x_db}"
	fi
	local x_sql=$2
	local -i x_iterate=$3
	local x_field _ x_value x_line
	local x_nl=$'\n'
	# shellcheck disable=SC2086
	{
		printf '%s\n' "${x_sql};"
		printf '%s\n' '.mode list'
		printf '%s\n' "select printf('${x_nl}EOF');"
		printf '%s\n' '.mode line'
	} >&${x_db[in]}
	x_db[iter]=1
	if (( x_iterate == 0 )); then
		__NS__flush "${!x_db}"
		return 0
	fi
	return 1
}


__NS__next() {
	pragma local_prefix x_
	 # shellcheck disable=SC2178
	local -n x_db=$1
	if [[ -z  ${x_db[in]} || -z ${x_db[out]} ]]; then
		printerror 'Database connection is closed'
		return 1
	fi
	if (( x_db[iter] != 1 )); then
		return 1
	fi
	local -n x_record=${retvar:?}
	x_record=()
	local x_field x_value x_line
	local IFS=$' '
	# shellcheck disable=SC2086
	while read -r x_field _ x_value; do
		if [[ ${x_field}${x_value} == EOF ]]; then
			unset  'x_db[iter]'
			return 1
		fi
		if [[ -z ${x_field} ]]; then
			continue
		fi
		while :; do # record found
	 		# shellcheck disable=SC2034
			x_record[$x_field]=${x_value}
			read -r x_field _ x_value
			if [[ -z ${x_field} ]]; then
				return 0
			fi
		done
	done <&${x_db[out]}
}


 __NS__flush() {
	pragma local_prefix x_
	 # shellcheck disable=SC2178
	local -n x_db=$1
	if (( x_db[iter] != 1 )); then
		return;
	fi
	local IFS=$' \t\n'
	local x_line
	# shellcheck disable=SC2086
	while read -r x_line; do
		if [[ ${x_line} == EOF ]]; then
			break
		fi
	done <&${x_db[out]}
	unset 'x_db[iter]'
 }


# $1: Var name of db connection descriptor
# $2: Query SQL
# $3: Output vars prefix (default: record_)
__NS__get_record() {
	pragma local_prefix x_
	 # shellcheck disable=SC2178
	local -n x_db=$1
	local x_sql=$2
	__NS__query "${!x_db}" "$x_sql" 1
	if __NS__next "${!x_db}"; then
		__NS__flush "${!x_db}"
		return 0
	else
		printerror 'Error while executing query %s' "${x_sql@Q}"
		return 1
	fi
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



