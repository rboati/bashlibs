#!/bin/bash

[[ -v BASH_IMPORT && ${#BASH_IMPORT[@]} != 0 ]] && return

if [[ -z ${BASH_LIBRARY_PATH-} ]]; then
	declare -g BASH_LIBRARY_PATH="$HOME/.local/lib/bash:/usr/local/lib/bash:/usr/lib/bash"
fi

# associative array
# absolute file path --> comma separated namespaces list
declare -gA BASH_IMPORT=( [$(readlink -e "${BASH_SOURCE[0]}")]='<empty>,' )




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
	fi
	local __DIR__="${__FILE__%/*}"

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
	else
		(( ${LOGLEVEL-0} >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_import "Importing from ${_type} path: '${_source_file}'${_ns:+ with namespace \"$_ns\"}" 1>&2
	fi


	BASH_IMPORT[${__FILE__}]+="${_ns:-<empty>},"

	local line key value lib
	while IFS='' read -r line; do
		if [[ $line =~ ^\s*bash_import\s+([-./_[:alnum:]]+)\s*([_[:alnum:]]+)?\s*$ ]]; then
			lib=${BASH_REMATCH[1]}
			lib=$(readlink -e "$lib")
			key=${BASH_REMATCH[2]}

			if [[ -n ${BASH_IMPORT[$lib]} ]]; then
				IFS=',' read -r -a _ns_list <<< "${BASH_IMPORT[$lib]%,}" # split
				if [[ ${_ns_list[0]} == '<empty>' ]]; then
					ns_map[$key]=''
				else
					ns_map[$key]=${_ns_list[0]}
				fi
			else
				ns_map[$key]=$key
			fi
		fi

		while [[ $line =~ ^(.*)(__NS[[:alnum:]]*__)(.*)$ ]]; do
			key=${BASH_REMATCH[2]}
			value=${ns_map[$key]:-${ns_map[__NS__]}}
			line=${BASH_REMATCH[1]}$value${BASH_REMATCH[3]}
		done
		printf -- '%s\n' "$line"
	done


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
}





ns_filter() {
	local line key value lib ns
	while IFS='' read -r line; do
		if [[ $line =~ ^\s*bash_import\s+([-./_[:alnum:]]+)\s*([_[:alnum:]]+)?\s*$ ]]; then
			lib=${BASH_REMATCH[1]}
			ns=${BASH_REMATCH[2]}
			ns_map[$ns]=
		fi

		while [[ $line =~ ^(.*)(__NS[[:alnum:]]*__)(.*)$ ]]; do
			key=${BASH_REMATCH[2]}
			value=${ns_map[$key]:-${ns_map[__NS__]}}
			line=${BASH_REMATCH[1]}$value${BASH_REMATCH[3]}
		done
		printf -- '%s\n' "$line"
	done
}

read_import_table() {
	local line lib ns
	while IFS='' read -r line; do
		while [[ $line =~ ^.*\#\*\s*import\s*([\.-_/[:alnum:]]+)\s*([_[:alnum:]]+)?$ ]]; do
			lib=${BASH_REMATCH[1]}
			ns=${BASH_REMATCH[2]}
		done
		printf -- '%s\n' "$line"
	done
}

import() {
	local libname="${1:?}"
	local -A ns_map
	ns_map[__NS__]=${2:-''}
	ns_map[__NS1__]=aaa_
	local libcode
	IFS='' read -r -d '' -- libcode

	ns_filter <<< "$libcode"
}

#set -x

bash_import ./liba __a__
bash_import ./libb __b__
bash_import ./libc __c__

declare -pF


