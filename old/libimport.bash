# Dependencies:
# cat, sed, readlink

[[ -v BASH_IMPORT && ${#BASH_IMPORT[@]} != 0 ]] && return

if [[ -z ${BASH_LIBRARY_PATH-} ]]; then
	declare -g BASH_LIBRARY_PATH="$HOME/.local/lib/bash:/usr/local/lib/bash:/usr/lib/bash"
fi

declare -ga BASH_IMPORT_STACK=()

# associative array
# absolute file path --> comma separated namespaces list
declare -gA BASH_IMPORT=( [$(readlink -e "${BASH_SOURCE[0]}")]='<empty>,' )



bash_import() {
	local __libimport_source_file="$1"
	local __libimport_ns="${2:-}"
	shift 2
	local __libimport_item IFS
	local -i __libimport_found=0
	local -a __libimport_namespaces
	local __libimport_type
	if [[ -z ${__FILE__-} ]]; then
		# shellcheck disable=SC2155
		local __FILE__="$(readlink -e "$0")"
		local __DIR__="${__FILE__%/*}"
	fi

	if [[ ${__libimport_source_file} == /* ]]; then
		# absolute path
		__libimport_type=absolute
		__FILE__="${__libimport_source_file}"
		__libimport_found=1
	elif [[ ${__libimport_source_file} == ./*  || ${__libimport_source_file} == ../* ]]; then
		# relative path
		__libimport_type=relative
		__FILE__="$__DIR__/${__libimport_source_file}"
		__libimport_found=1
	else
		# search library path
		__libimport_type=library
		IFS=':'
		for __libimport_item in $BASH_LIBRARY_PATH; do
			if [[ -r ${__libimport_item}/${__libimport_source_file} ]]; then
				__FILE__="${__libimport_item}/${__libimport_source_file}"
				__libimport_found=1
				break
			fi
		done
		unset IFS
	fi
	if (( __libimport_found == 1 )); then
		if ! __FILE__="$(readlink -e "${__FILE__}")" || [[ -z ${__FILE__} ]]; then
			__libimport_found=0
		fi
	fi
	if (( __libimport_found == 0 )); then
		(( LOGLEVEL >= 2 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' ERROR bash_import "Importing from ${__libimport_type} path: '${__libimport_source_file}' not __libimport_found! (${__FILE__})" 1>&2
		exit 1
	fi

	if [[ -n ${BASH_IMPORT[${__FILE__}]-} ]]; then
		IFS=',' read -r -a __libimport_namespaces <<< "${BASH_IMPORT[${__FILE__}]%,}"
		unset IFS
		for __libimport_item in "${__libimport_namespaces[@]}"; do
			if [[ ${__libimport_ns:-<empty>} == "${__libimport_item}" ]]; then
				(( LOGLEVEL >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_import "Importing from ${__libimport_type} path: '${__libimport_source_file}' already imported with namespace '${__libimport_ns:-<empty>}', skipping." 1>&2
				return 2
			fi
		done
		if (( LOGLEVEL >= 5 )); then
			printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s' DEBUG bash_import "Importing from ${__libimport_type} path: '${__libimport_source_file}' already imported with other namespaces (${BASH_IMPORT[${__FILE__}]%,}), importing with " 1>&2
			if [[ -z $__libimport_ns ]]; then
				printf '%s\n' "no namespace." 1>&2
			else
				printf '%s\n' "namespace \"$__libimport_ns\"." 1>&2
			fi
		fi
	else
		(( ${LOGLEVEL-0} >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_import "Importing from ${__libimport_type} path: '${__libimport_source_file}'${__libimport_ns:+ with namespace \"$__libimport_ns\"}" 1>&2
	fi


	BASH_IMPORT_STACK+=( "$__DIR__" )
	__DIR__="${__FILE__%/*}"
	BASH_IMPORT[${__FILE__}]+="${__libimport_ns:-<empty>},"
	unset __libimport_source_file __libimport_item __libimport_found __libimport_namespaces
	if [[ ${__libimport_ns} == __NS__ ]]; then
		# shellcheck disable=SC1090
		source "${__FILE__}"
	elif [[ -n ${DEBUG-} ]] && (( DEBUG > 0 )); then
		local -r __libimport_tmpdir="/tmp/$USER/libimport.bash/$$"
		mkdir -p "${__libimport_tmpdir}${__DIR__}"
		sed -e "s/\<__[N]S__/${__libimport_ns}/g" > "${__libimport_tmpdir}${__DIR__}/${__FILE__##*/}" "${__FILE__}"
		# shellcheck disable=SC1090
		source "${__libimport_tmpdir}${__DIR__}/${__FILE__##*/}"
		(( DEBUG == 1 )) && rm -rf "${__libimport_tmpdir}"
	else
		eval "$(sed -e "s/\<__[N]S__/${__libimport_ns}/g" "${__FILE__}")"
	fi
	__DIR__="${BASH_IMPORT_STACK[-1]}"
	unset 'BASH_IMPORT_STACK[-1]'
}


bash_source() {
	local __libimport_source_file="$1"
	shift 2
	local __libimport_item IFS
	local -i __libimport_found=0
	local -a __libimport_namespaces
	local __libimport_type
	if [[ -z ${__FILE__} ]]; then
		# shellcheck disable=SC2155
		local __FILE__="$(readlink -e "$0")"
		local __DIR__="${__FILE__%/*}"
	fi

	if [[ ${__libimport_source_file} == /* ]]; then
		# absolute path
		__libimport_type=absolute
		__FILE__="${__libimport_source_file}"
		__libimport_found=1
	elif [[ ${__libimport_source_file} == ./*  || ${__libimport_source_file} == ../* ]]; then
		# relative path
		__libimport_type=relative
		__FILE__="$__DIR__/${__libimport_source_file}"
		__libimport_found=1
	else
		# search library path
		__libimport_type=library
		IFS=':'
		for __libimport_item in $BASH_LIBRARY_PATH; do
			if [[ -r ${__libimport_item}/${__libimport_source_file} ]]; then
				__FILE__="${__libimport_item}/${__libimport_source_file}"
				__libimport_found=1
				break
			fi
		done
		unset IFS
	fi
	if (( __libimport_found == 1 )); then
		if ! __FILE__="$(readlink -e "${__FILE__}")" || [[ -z ${__FILE__} ]]; then
			__libimport_found=0
		fi
	fi
	if (( __libimport_found == 0 )); then
		(( LOGLEVEL >= 2 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' ERROR bash_source "Sourcing from ${__libimport_type} path: '${__libimport_source_file}' not __libimport_found! (${__FILE__})" 1>&2
		exit 1
	fi

	if [[ -n ${BASH_IMPORT[${__FILE__}]} ]]; then
		IFS=',' read -r -a __libimport_namespaces <<< "${BASH_IMPORT[${__FILE__}]%,}"
		unset IFS
		for __libimport_item in "${__libimport_namespaces[@]}"; do
			if [[ ${__libimport_ns:-<empty>} == "${__libimport_item}" ]]; then
				(( LOGLEVEL >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_source "Sourcing from ${__libimport_type} path: '${__libimport_source_file}' already imported with namespace '${__libimport_ns:-<empty>}', skipping." 1>&2
				return 2
			fi
		done
		if (( LOGLEVEL >= 5 )); then
			printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s' DEBUG bash_source "Sourcing from ${__libimport_type} path: '${__libimport_source_file}' already imported with other namespaces (${BASH_IMPORT[${__FILE__}]%,}), importing with " 1>&2
			if [[ -z $__libimport_ns ]]; then
				printf '%s\n' "no namespace." 1>&2
			else
				printf '%s\n' "namespace \"$__libimport_ns\"." 1>&2
			fi
		fi
	else
		(( LOGLEVEL >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_source "Sourcing from ${__libimport_type} path: '${__libimport_source_file}'${__libimport_ns:+ with namespace \"$__libimport_ns\"}" 1>&2
	fi

	BASH_IMPORT_STACK+=( "$__DIR__" )
	__DIR__="${__FILE__%/*}"
	BASH_IMPORT[${__FILE__}]+="<empty>,"
	unset __libimport_source_file __libimport_item __libimport_found __libimport_namespaces
	# shellcheck disable=SC1090
	source "${__FILE__}"
	__DIR__="${BASH_IMPORT_STACK[-1]}"
	unset 'BASH_IMPORT_STACK[-1]'
}


bash_import() {
	local _source_file="$1"
	local _ns="${2:-}"
	shift 2
	local _item IFS
	local -i _found=0
	local -a _ns_list=()
	local -A _ns_map=()
	local _type
	_ns_map[__NS__]=${_ns}

	if [[ -z ${__FILE__-} ]]; then
		# shellcheck disable=SC2155
		local __FILE__="$(readlink -e "$0")"
		local __DIR__="${__FILE__%/*}"
	fi

	if [[ ${_source_file} == /* ]]; then
		# absolute path
		_type=absolute
		__FILE__="${_source_file}"
		_found=1
	elif [[ ${_source_file} == ./*  || ${_source_file} == ../* ]]; then
		# relative path
		_type=relative
		__FILE__="$__DIR__/${_source_file}"
		_found=1
	else
		# search library path
		_type=library
		IFS=':'
		for _item in $BASH_LIBRARY_PATH; do
			if [[ -r ${_item}/${_source_file} ]]; then
				__FILE__="${_item}/${_source_file}"
				_found=1
				break
			fi
		done
		unset IFS
	fi
	if (( _found == 1 )); then
		if ! __FILE__="$(readlink -e "${__FILE__}")" || [[ -z ${__FILE__} ]]; then
			_found=0
		fi
	fi
	if (( _found == 0 )); then
		(( LOGLEVEL >= 2 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' ERROR bash_import "Importing from ${_type} path: '${_source_file}' not found! (${__FILE__})" 1>&2
		exit 1
	fi

	if [[ -n ${BASH_IMPORT[${__FILE__}]-} ]]; then
		IFS=',' read -r -a _ns_list <<< "${BASH_IMPORT[${__FILE__}]%,}" # split
		unset IFS
		for _item in "${_ns_list[@]}"; do
			if [[ ${_ns:-<empty>} == "${_item}" ]]; then
				(( LOGLEVEL >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_import "Importing from ${_type} path: '${_source_file}' already imported with namespace '${_ns:-<empty>}', skipping." 1>&2
				return 2
			fi
		done
		if (( LOGLEVEL >= 5 )); then
			printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s' DEBUG bash_import "Importing from ${_type} path: '${_source_file}' already imported with other namespaces (${BASH_IMPORT[${__FILE__}]%,}), importing with " 1>&2
			if [[ -z $_ns ]]; then
				printf '%s\n' "no namespace." 1>&2
			else
				printf '%s\n' "namespace \"$_ns\"." 1>&2
			fi
		fi

		if [[ $_ns == __NS*__ ]]; then
			_ns_map[$_ns]=${_ns_list[0]}
		fi
	else
		(( ${LOGLEVEL-0} >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_import "Importing from ${_type} path: '${_source_file}'${_ns:+ with namespace \"$_ns\"}" 1>&2
	fi
	declare -p _ns_map


	BASH_IMPORT_STACK+=( "$__DIR__" )
	__DIR__="${__FILE__%/*}"
	BASH_IMPORT[${__FILE__}]+="${_ns:-<empty>},"
	unset _source_file _item _found _ns_list _ns_map
	if [[ ${_ns} == __NS__ ]]; then
		# shellcheck disable=SC1090
		source "${__FILE__}"
	elif [[ -n ${DEBUG-} ]] && (( DEBUG > 0 )); then
		local -r _tmpdir="/tmp/$USER/libimport.bash/$$"
		mkdir -p "${_tmpdir}${__DIR__}"
		#sed -e "s/\<__[N]S__/${_ns}/g" > "${_tmpdir}${__DIR__}/${__FILE__##*/}" < "${__FILE__}"
		ns_filter > "${_tmpdir}${__DIR__}/${__FILE__##*/}" < "${__FILE__}"
		# shellcheck disable=SC1090
		source "${_tmpdir}${__DIR__}/${__FILE__##*/}"
		(( DEBUG == 1 )) && rm -rf "${_tmpdir}"
	else
		eval "$(sed -e "s/\<__[N]S__/${_ns}/g" "${__FILE__}")"
	fi
	__DIR__="${BASH_IMPORT_STACK[-1]}"
	unset 'BASH_IMPORT_STACK[-1]'
}


ns_filter() {
	local line
	local ns
	while read -r line; do
		if [[ $line =~ ^(.*)\<__NS__(.*)$ ]]; then
			printf -- '%s%s%s\n' "${BASH_REMATCH[1]}" "$_ns" "${BASH_REMATCH[3]}"
		elif [[ $line =~ ^(.*)\<(__NS[[:alnum:]]+__)(.*)$ ]]; then
			ns=${_ns_map[${BASH_REMATCH[2]}]}
			printf -- '%s%s%s\n' "${BASH_REMATCH[1]}" "$ns" "${BASH_REMATCH[3]}"
		else
			printf -- '%s\n' "$line"
		fi
	done
}