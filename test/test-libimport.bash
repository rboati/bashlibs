
declare -ga funlist
read -r -a funlist -d '' < <(declare -pF | while read -r _ _ f; do printf -- '%s\n' "$f"; done )
unset -f "${funlist[@]}"
unset -v funlist

# shellcheck disable=SC2120
test_assert() {
	local -i exit_code=$?
	local msg=${1:-}
	local file func line
	local -i lineno n=0
	local -i ctx=${ASSERT_CTX:-2} # number of context lines to print
	if (( exit_code != 0 )); then
		file=${BASH_SOURCE[1]}
		func=${FUNCNAME[1]}
		lineno=${BASH_LINENO[0]}
		printf 'Assertion in %s (see %s:%d)%s\n' "$func" "$file" "$lineno" "${msg:+: $msg}"
		if (( ctx >= 0 )); then
			[[ -r $file ]] && cat -n -- "$file" | sed -n "$((lineno - ctx)),+$((ctx * 2))p;$((lineno + ctx))q" | while read -r line; do
				if (( n++ == ctx )); then
					printf '%s\n' "$line"
				else
					printf '\e[2m%s\e[0m\n' "$line"
				fi
			done
			printf '\n'
		fi
		exit $exit_code
	fi 1>&2
	return $exit_code
}

set_return_code() {
	local -i exit_code=${1:-0}
	return "$exit_code"
}



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

	local _line _key _value _lib _libcode=""

	while IFS='' read -r _line; do
		if [[ $_line =~ ^[[:space:]]*bash_import[[:space:]]+([-./_[:alnum:]]+)[[:space:]]*([_[:alnum:]]+)?[[:space:]]*(\#.*)?$ ]]; then
			set -x
			_lib=${BASH_REMATCH[1]}
			_lib=$(readlink -e "$_lib")
			_key=${BASH_REMATCH[2]}

			if [[ -n ${BASH_IMPORT[$_lib]} ]]; then
				IFS=',' read -r -a _ns_list <<< "${BASH_IMPORT[$_lib]%,}" # split
				if [[ ${_ns_list[0]} == '<empty>' ]]; then
					_ns_map[$_key]=''
				else
					_ns_map[$_key]=$_ns
				fi
			else
				_ns_map[$_key]=$_key
			fi
			set +x

		fi

		while [[ $_line =~ ^(.*)(__NS[[:alnum:]]*__)(.*)$ ]]; do
			_key=${BASH_REMATCH[2]}
			_value=${_ns_map[$_key]}
			if [[ _value${_ns_map[__NS__]}}]]
			_value=${_ns_map[$_key]:-${_ns_map[__NS__]}}
			_line=${BASH_REMATCH[1]}$_value${BASH_REMATCH[3]}
			[[ $_value == __NS*__ && ${_ns_map[$_value]} == "$_value" ]] && break
			declare -p _value _ns _ns_map
			sleep 0.01
		done
		_libcode+=${_line}$'\n'

	done < "${__FILE__}"
	printf -- '-----------------------------------------------\n'

	unset _source_file _item _found _ns_list _ns_map
	if [[ -n ${DEBUG-} ]] && (( DEBUG > 0 )); then
		local -r _tmpdir="/tmp/$USER/libimport.bash/$$/${_ns:-<empty>}"
		mkdir -p "${_tmpdir}${__DIR__}"
		printf -- '%s' "$_libcode" > "${_tmpdir}${__DIR__}/${__FILE__##*/}"
		# shellcheck disable=SC1090
		source "${_tmpdir}${__DIR__}/${__FILE__##*/}"
		local -i _exit_code=$?
		(( DEBUG == 1 )) && rm -rf "${_tmpdir}"
		return $_exit_code
	else
		eval "$_libcode"
	fi
}



shopt -s extdebug

export DEBUG=2
#set -e
#source ../libimport.bash || test_assert

#set -x

bash_import ./libc.bash || test_assert
declare -pF func &> /dev/null || test_assert

#bash_import ./libb.bash BBB_ || test_assert
#declare -pF BBB_funb &> /dev/null || test_assert


bash_import ./liba.bash AAA_ || test_assert
#declare -pF AAA_funa &> /dev/null || test_assert
declare -pF AAA_funb &> /dev/null && test_assert

declare -F | grep '.*fun.*'
