
# external commands useed: readlink

if [[ -z ${BASH_LIBRARY_PATH-} ]]; then
	declare -g BASH_LIBRARY_PATH="$HOME/.local/lib/bash:/usr/local/lib/bash:/usr/lib/bash"
fi

__libimport_log() {
	local -ir x=$?; local level=${1^^}; local fmt=$2; shift;
	local loglevel=${LOGLEVEL:-4}
	local color level_nr
	case $level in
		FATAL) level_nr=1; color='1;31';;
		ERROR) level_nr=2; color='31'  ;;
		WARN)  level_nr=3; color='33'  ;;
		INFO)  level_nr=4; color='34'  ;;
		DEBUG) level_nr=5; color='37'  ;;
		TRACE) level_nr=6; color='1'   ;;
	esac
	if (( level_nr <= loglevel )); then
		# shellcheck disable=SC2059
		printf -- "\e[${color}m${level}\e[0m:\e[${color}m:libimport\e[0m:$fmt\n" "$@" >&2
	fi
	return $x
}

__libimport_generate_functions_maps() {
	local ns=${1:-}
	local -a functions
	IFS=$'\n' read -r -d '' -a functions < <(compgen -A function)
	local -A __libimport_FUNCTIONS_MAP
	local -A __libimport_REQUIRED_FUNCTIONS_MAP
	local -A __libimport_REQUIRED_COMMANDS_MAP
	local fun line token
	local -a token_list
	local IFS=$' \t\n'
	for fun in "${functions[@]}"; do
		[[ $fun == "${FUNCNAME[0]}" ]] && continue
		[[ $fun == bash_import ]] && continue
		[[ $fun == __libimport_log ]] && continue

		local -A required_functions=() required_commands=()
		local body=''
		while read -r line; do
			# look for directives:
			# .require_functions fun1 fun2 ...
			# .require_commands cmd1 cmd2 ...
			line=${line//__NS__/$ns}
			if [[ $line =~ ^[[:space:]]*'.require_'([_[:alnum:]]+)[[:space:]]+(.*)\;$ ]]; then
				case ${BASH_REMATCH[1]} in
					functions)
						# shellcheck disable=SC2162
						read -d '' -a token_list <<< "${BASH_REMATCH[2]}"
						for token in "${token_list[@]}"; do
							required_functions[${token}]=1
						done
					;;
					commands)
						# shellcheck disable=SC2162
						read -d '' -a token_list <<< "${BASH_REMATCH[2]}"
						for token in "${token_list[@]}"; do
							required_commands[${token@Q}]=1
						done
					;;
				esac
				continue
			fi
			body+=${line}$'\n'
		done < <(declare -pf "$fun")
		fun=${fun/__NS__/$ns}
		__libimport_FUNCTIONS_MAP[$fun]=$body
		__libimport_REQUIRED_FUNCTIONS_MAP[$fun]=${!required_functions[*]}
		__libimport_REQUIRED_COMMANDS_MAP[$fun]=${!required_commands[*]}
	done
	declare -p __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP __libimport_FUNCTIONS_MAP
}


bash_import() {
	local __libimport_module_path=${1%=*}
	local __libimport_ns=''
	shift
	while (( ${#@} )); do
		case $1 in
			--) shift
				break
				;;
			--prefix|-p)
				__libimport_ns=$2
				shift 2
				;;
			-*) #TODO
				shift
				break
				;;
			*)
				break
				;;
		esac
	done
	local IFS=$' \t\n'
	local -a __libimport_library_path

	local __FILE__=${BASH_SOURCE[1]}
	local __DIR__=${__FILE__%/*}

	local __libimport_import_type __libimport_module_found
	{
		if [[ ${__libimport_module_path} == /* ]]; then
			# absolute path
			__libimport_import_type=absolute
			__FILE__=${__libimport_module_path}
			__libimport_module_found=1
		elif [[ ${__libimport_module_path} == ./*  || ${__libimport_module_path} == ../* ]]; then
			# relative path
			__libimport_import_type=relative
			__FILE__=$__DIR__/${__libimport_module_path}
			__libimport_module_found=1
		else
			# search library path
			__libimport_import_type=library
			IFS=':' read -r -d '' -a __libimport_library_path <<<"$BASH_LIBRARY_PATH"
			local __libimport_item
			for __libimport_item in "${__libimport_library_path[@]}"; do
				if [[ -r ${__libimport_item}/${__libimport_module_path} ]]; then
					__FILE__=${__libimport_item}/${__libimport_module_path}
					__libimport_module_found=1
					break
				fi
			done
			unset -v __libimport_item
		fi
	}

	if (( __libimport_module_found == 1 )); then
		if ! __FILE__=$(readlink -e "$__FILE__") || [[ -z $__FILE__ ]]; then
			__libimport_module_found=0
		fi
	fi

	if (( __libimport_module_found == 0 )); then
		__libimport_log fatal "Importing from ${__libimport_import_type} path: '${__libimport_module_path}' not found! (${__FILE__})"
		exit 1
	fi
	unset -v __libimport_import_type __libimport_module_found


	 # create symbols data structures
	local -A __libimport_FUNCTIONS_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP

	eval "$(bash --norc -s <<- EOF
			builtin source "${BASH_SOURCE[0]}" > /dev/null
			builtin source "$__FILE__" > /dev/null
			__libimport_generate_functions_maps "$__libimport_ns"
		EOF
	)"

	# the import list defaults to all functions
	{
		if (( $# == 0 )); then
			set -- "${!__libimport_FUNCTIONS_MAP[@]}"
		else
			local -a __libimport_tmp_list=()
			for __libimport_item in "$@"; do
				__libimport_tmp_list+=( "${__libimport_ns}${__libimport_item}" )
			done
			set -- "${__libimport_tmp_list[@]}"
			unset -v __libimport_tmp_list
		fi

	}

	#region Topological sort
	local -A __libimport_adj_map=()
	{ # preparing __libimport_adj_map
		local -A __libimport_tmp_set=()
		local __libimport_item __libimport_item2
		for __libimport_item in "$@"; do
			if [[ -v __libimport_FUNCTIONS_MAP[$__libimport_item] ]]; then
				__libimport_tmp_set[$__libimport_item]=1
			else
				__libimport_log warn "Missing symbol '$__libimport_item' in module ${__FILE__}"
			fi
		done
		# now __libimport_tmp_set is the set of requested symbols
		while (( ${#__libimport_tmp_set[@]} > 0 )); do
			for __libimport_item in "${!__libimport_tmp_set[@]}"; do
				__libimport_adj_map[${__libimport_item}]=${__libimport_REQUIRED_FUNCTIONS_MAP[${__libimport_item}]}
				unset -v "__libimport_tmp_set[$__libimport_item]"
				for __libimport_item2 in ${__libimport_REQUIRED_FUNCTIONS_MAP[${__libimport_item}]}; do __libimport_tmp_set[${__libimport_item2}]=1; done
			done
		done
		[[ -v '__libimport_FUNCTIONS_MAP[__init__]' ]] && __libimport_adj_map[__init__]=""
		unset -v __libimport_tmp_set __libimport_item __libimport_item2
	}

	local -a __libimport_sorted_list=()
	{ # topological sort
		local -a __libimport_tmp_stack=() __libimport_tmp_list
		local -i __libimport_index
		local __libimport_item

		while :; do
			for __libimport_item in "${!__libimport_adj_map[@]}"; do
				if [[ ! -v __libimport_adj_map[${__libimport_item}] || ${__libimport_adj_map[${__libimport_item}]} == '' ]]; then
					__libimport_tmp_stack+=( "${__libimport_item}" )
					unset -v "__libimport_adj_map[${__libimport_item}]"
				fi
			done
			(( ${#__libimport_tmp_stack[@]} == 0 )) && break
			local __libimport_stack_item=${__libimport_tmp_stack[0]}; unset -v '__libimport_tmp_stack[0]'; __libimport_tmp_stack=( "${__libimport_tmp_stack[@]}" )
			__libimport_sorted_list+=( "$__libimport_stack_item" )
			for __libimport_item in "${!__libimport_adj_map[@]}"; do
				read -r -d '' -a __libimport_tmp_list <<< "${__libimport_adj_map[${__libimport_item}]}"
				for __libimport_index in "${!__libimport_tmp_list[@]}"; do
					if [[ ${__libimport_tmp_list[__libimport_index]} == "$__libimport_stack_item" ]]; then
						unset -v '__libimport_tmp_list[__libimport_index]'
					fi
				done
				__libimport_adj_map[${__libimport_item}]=${__libimport_tmp_list[*]}
			done
		done
		unset -v __libimport_tmp_stack __libimport_tmp_list __libimport_index __libimport_item
	}

	unset -v __libimport_adj_map
	#endregion Topological sort

	__DIR__="${__FILE__%/*}"

	#region Importing requested symbols and their dependencies
	{
		local __libimport_item __libimport_item2
		local -A __libimport_commands_set=()
		for __libimport_item in "${__libimport_sorted_list[@]}"; do
			for __libimport_item2 in ${__libimport_REQUIRED_COMMANDS_MAP[${__libimport_item}]}; do
				[[ -v __libimport_commands_set[${__libimport_item2}] ]] && continue
				# accept also aliases and functions as command replacement
				type -at "${__libimport_item2}" &> /dev/null || exit 3
				__libimport_commands_set[${__libimport_item2}]=1
			done
			if [[ -v __libimport_FUNCTIONS_MAP[${__libimport_item}] ]]; then
				# shellcheck disable=SC2001
				if declare -F "$__libimport_item" &> /dev/null && [[ $__libimport_item != __init__ ]]; then
					__libimport_log warn "A function '$__libimport_item' alredy exists, overwriting."
				fi
				eval "${__libimport_FUNCTIONS_MAP[${__libimport_item}]}"
			fi
		done
		unset -v __libimport_item __libimport_item2 __libimport_commands_set
		unset -v __libimport_sorted_list
	}
	#region Importing requested symbols and their dependencies

	unset -v __libimport_module_path __libimport_module_found
	unset -v __libimport_FUNCTIONS_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP

	#region Execute __init__ if found
	if declare -F __init__ &> /dev/null; then
		__init__
		unset -f __init__
	fi
}

