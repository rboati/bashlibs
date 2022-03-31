# external commands useed: readlink

#region Bashlibs import
if [[ -z ${BASH_LIBRARY_PATH-} ]]; then
	declare -g BASH_LIBRARY_PATH="$HOME/.local/lib/bash:/usr/local/lib/bash:/usr/lib/bash"
fi

function comment() {
	local -i exit_code=$?
	:
	return $exit_code
}

#region comment
comment <<-'EOC'
	Comment example
EOC
#endregion


uuid_compress() {
	local uuid=$1
	local val=${uuid//-/}
	local output_alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' #62
	local -i output_base=${#output_alphabet}
	local -ai val_arr
	local -i i
	for (( i = 0; i < ${#val}; ++i )); do
		(( val_arr[i] = 0x${val:i:1} ))
	done

	local -i val_count=${#val_arr[@]}
	local compressed_uuid=''
	while # "do while" bash pattern
		local -i divide=0
		local -i new_count=0
		local -i i
		for (( i = 0; i < val_count; ++i )); do
			(( divide = divide * 16 + val_arr[i] ))
			if (( divide >= output_base )); then
				(( val_arr[new_count++] = divide / output_base ))
				(( divide = divide % output_base ))
			elif (( new_count > 0 )); then
				(( val_arr[new_count++] = 0 ))
			fi
		done
		(( val_count = new_count ))
		compressed_uuid=${output_alphabet:divide:1}${compressed_uuid}
		(( new_count != 0 ))
	do :; done
	local "${retvar:?}" && upvar "$retvar" "$compressed_uuid"
}

comment << 'EOC'
__libimport_generate_functions_maps() {
	local ns=${1:-}
	local -a function_list
	IFS=$'\n' read -r -d '' -a function_list < <(compgen -A function)
	local -A __libimport_FUNCTION_CODE_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP
	local fun line token
	local -a token_list
	local IFS=$' \t\n'
	local global_prefix='__NS__'
	local pragma_re='^\s*pragma\s+(\w+)\s*(.*);$'
	local prefix_re1='^(.*\b)' prefix_re2='(\w+.*)$'
	for fun in "${function_list[@]}"; do
		[[ $fun == "${FUNCNAME[0]}" ]] && continue
		[[ $fun == bash_import ]] && continue
		local uuid=''
		local local_prefix=''
		local -A required_function_set=() required_command_set=()
		local body=''
		while read -r line; do
			if [[ $line =~ $pragma_re ]]; then
				# shellcheck disable=SC2162
				read -d '' -a token_list <<<"${BASH_REMATCH[2]}"
				case ${BASH_REMATCH[1]} in
				require_functions)
					for token in "${token_list[@]}"; do
						required_function_set[$token]=1
					done
					continue
					;;
				require_commands)
					for token in "${token_list[@]}"; do
						required_command_set[$token]=1
					done
					continue
					;;
				local_prefix)
					if (( ${#token_list[@]} > 0 )); then
						local_prefix=${token_list[0]}
						if [[ -z $uuid ]]; then
							IFS= read -r -d '' uuid < "/proc/sys/kernel/random/uuid"
							retvar=uuid uuid_compress "$uuid"
						fi
					else
						local_prefix=''
					fi
					continue
					;;
				esac
			fi
			# Replace local namespace
			if [[ -n $local_prefix ]]; then
				local undone_part=$line done_part=''
				# Avoiding infinite loop by looking for a match only in the previously unmatched part
				# Because of the greedy operator *, the unmatched part is on the left (match group 2)
				while [[ $undone_part =~ ${prefix_re1}"$local_prefix"${prefix_re2} ]]; do
					undone_part=${BASH_REMATCH[1]}
					done_part=${ns}${BASH_REMATCH[2]}$done_part
					line=${undone_part}${done_part}
				done
			fi

			# Replace global namespace
			local undone_part=$line done_part=''
			# Avoiding infinite loop by looking for a match only in the previously unmatched part
			# Because of the greedy operator *, the unmatched part is on the left (match group 2)
			while [[ $undone_part =~ ${prefix_re1}"$global_prefix"${prefix_re2} ]]; do
				undone_part=${BASH_REMATCH[1]}
				done_part=${ns}${BASH_REMATCH[2]}$done_part
				line=${undone_part}${done_part}
			done
			body+=${line}$'\n'
		done < <(declare -pf "$fun")
		fun=${fun/$global_prefix/$ns}
		__libimport_FUNCTION_CODE_MAP[$fun]=$body
		local -a required_function_list=( "${!required_function_set[@]}" )
		__libimport_REQUIRED_FUNCTIONS_MAP[$fun]=${required_function_list[*]/#$global_prefix/$ns}
		__libimport_REQUIRED_COMMANDS_MAP[$fun]=${!required_command_set[*]}
	done
	declare -p __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP __libimport_FUNCTION_CODE_MAP
}

bash_import() {
	local __libimport_module_path=${1%=*}
	local __libimport_ns=''
	shift
	while ((${#@})); do
		case $1 in
		--)
			shift
			break
			;;
		--prefix | -p)
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

	#region Find library
	local __libimport_import_type __libimport_module_found
	if [[ ${__libimport_module_path} == /* ]]; then
		# absolute path
		__libimport_import_type=absolute
		__FILE__=${__libimport_module_path}
		__libimport_module_found=1
	elif [[ ${__libimport_module_path} == ./* || ${__libimport_module_path} == ../* ]]; then
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

	if ((__libimport_module_found == 1)); then
		if ! __FILE__=$(readlink -e "$__FILE__") || [[ -z $__FILE__ ]]; then
			__libimport_module_found=0
		fi
	fi

	if ((__libimport_module_found == 0)); then
		die "Importing from ${__libimport_import_type} path: '${__libimport_module_path}' not found! (${__FILE__})"
	fi
	unset -v __libimport_import_type __libimport_module_found
	#endregion Find library

	#region Create symbol data structures
	local -A __libimport_FUNCTION_CODE_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP

	eval "$(
		exec bash --noprofile --norc -s <<-EOF
			{
				builtin source "${BASH_SOURCE[0]}"
				builtin source "$__FILE__"
			} > /dev/null
			__libimport_generate_functions_maps "$__libimport_ns"
		EOF
	)"
	#endregion Create symbol data structures


	# the import list defaults to all functions
	{
		if (($# == 0)); then # default: import all symbols
			local -a __libimport_tmp_list=()
			local __libimport_item
			for __libimport_item in "${!__libimport_FUNCTION_CODE_MAP[@]}"; do
				if [[ ${__libimport_item} == ${__libimport_ns}* ]]; then
					__libimport_tmp_list+=("${__libimport_item}")
				fi
			done
			set -- "${__libimport_tmp_list[@]}"
			#set -- "${!__libimport_FUNCTION_CODE_MAP[@]}"
		else
			set -- "${@/#/${__libimport_ns}}" # oneliner: add prefix to all elements in the list
		fi

	}

	#region Topological sort
	local -A __libimport_adj_map=()
	{ # preparing __libimport_adj_map
		local -A __libimport_tmp_set=()
		local __libimport_item __libimport_item2
		for __libimport_item in "$@"; do
			if [[ -v __libimport_FUNCTION_CODE_MAP[$__libimport_item] ]]; then
				__libimport_tmp_set[$__libimport_item]=1
			else
				printwarn "Missing symbol '$__libimport_item' in module ${__FILE__}"
			fi
		done
		# now __libimport_tmp_set is the set of requested symbols
		while ((${#__libimport_tmp_set[@]} > 0)); do
			for __libimport_item in "${!__libimport_tmp_set[@]}"; do
				__libimport_adj_map[${__libimport_item}]=${__libimport_REQUIRED_FUNCTIONS_MAP[${__libimport_item}]}
				unset -v '__libimport_tmp_set[$__libimport_item]'
				for __libimport_item2 in ${__libimport_REQUIRED_FUNCTIONS_MAP[${__libimport_item}]}; do __libimport_tmp_set[${__libimport_item2}]=1; done
			done
		done
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
					__libimport_tmp_stack+=("${__libimport_item}")
					unset -v '__libimport_adj_map[$__libimport_item]'
				fi
			done
			((${#__libimport_tmp_stack[@]} == 0)) && break
			local __libimport_stack_item=${__libimport_tmp_stack[0]}
			unset -v '__libimport_tmp_stack[0]'
			__libimport_tmp_stack=("${__libimport_tmp_stack[@]}")
			__libimport_sorted_list+=("$__libimport_stack_item")
			for __libimport_item in "${!__libimport_adj_map[@]}"; do
				read -r -d '' -a __libimport_tmp_list <<<"${__libimport_adj_map[${__libimport_item}]}"
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
				type -at "${__libimport_item2}" &>/dev/null || exit 3
				__libimport_commands_set[${__libimport_item2}]=1
			done
			if [[ -v __libimport_FUNCTION_CODE_MAP[${__libimport_item}] ]]; then
				# shellcheck disable=SC2001
				if declare -F "$__libimport_item" &>/dev/null; then
					printwarn "A function '$__libimport_item' already exists, overwriting."
				fi
				printtrace 'About to eval "%s"' "$__libimport_item"
				eval "${__libimport_FUNCTION_CODE_MAP[$__libimport_item]}"
				printtrace 'End of eval "%s"' "$__libimport_item"

				if [[ -n $STRIP_PRAGMAS ]]; then
					# shellcheck disable=SC2086
					IFS=$' \t\n,:' read -r -d '' -a __libimport_tmp_list <<< "$STRIP_PRAGMAS"
					printf -v __libimport_item2 -- '%s,' "${__libimport_tmp_list[@]}" && __libimport_item2=${__libimport_item2%,} # string join
					printinfo 'Stripping function %s of pragmas %s' "$__libimport_item" "$__libimport_item2"
					strip_function "$__libimport_item" "${__libimport_tmp_list[@]}"
				fi
			fi
		done
		if [[ -n $DEBUG ]]; then
			IFS= read -r __libimport_item2 < '/proc/sys/kernel/random/uuid'
			__libimport_item2="/tmp/$USER/$$/$__libimport_item2-${__FILE__##*/}"
			mkdir -p "/tmp/$USER/$$/"
			for __libimport_item in "${__libimport_sorted_list[@]}"; do
				declare -f "$__libimport_item"
			done > "$__libimport_item2"
			# shellcheck disable=SC1090
			source "$__libimport_item2"
		fi
		unset -v __libimport_item __libimport_item2 __libimport_commands_set
		unset -v __libimport_sorted_list
	}
	#endregion Importing requested symbols and their dependencies

	unset -v __libimport_module_path __libimport_module_found
	unset -v __libimport_FUNCTION_CODE_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP
	unset -v "${!__libimport_@}"
}
EOC


__libimport_filter_function_code() {
	local ns=${1:?}
	local line token
	local IFS=$' \t\n'
	local global_prefix='__N''S__'
	local pragma_re='^\s*pragma\s+(\w+)\s*(.*);$'
	local prefix_re1='^(.*\b)' prefix_re2='(\w+.*)$'
	local uuid=''
	local local_prefix=''
	local body=''
	local -a token_list
	while read -r line; do
		#region Replace local pragmas
		if [[ $line =~ $pragma_re ]]; then
			# shellcheck disable=SC2162
			read -d '' -a token_list <<<"${BASH_REMATCH[2]}"
			case ${BASH_REMATCH[1]} in
				local_prefix)
					if (( ${#token_list[@]} > 0 )); then
						local_prefix=${token_list[0]}
						if [[ -z $uuid ]]; then
							IFS= read -r -d '' uuid < '/proc/sys/kernel/random/uuid'
							retvar=uuid uuid_compress "$uuid"
						fi
					else
						local_prefix=''
					fi
					continue
					;;
				# TODO: filter local pragmas
			esac
		fi
		#endregion Replace local pragmas

		#region Replace namespace prefixes
		# Replace local namespace
		if [[ -n $local_prefix ]]; then
			local undone_part=$line done_part=''
			# Avoiding infinite loop by looking for a match only in the previously unmatched part
			# Because of the greedy operator *, the unmatched part is on the left (match group 2)
			while [[ $undone_part =~ ${prefix_re1}"$local_prefix"${prefix_re2} ]]; do
				undone_part=${BASH_REMATCH[1]}
				done_part=__${uuid}_${BASH_REMATCH[2]}${done_part}
				line=${undone_part}${done_part}
			done
		fi

		# Replace global namespace
		local undone_part=$line done_part=''
		# Avoiding infinite loop by looking for a match only in the previously unmatched part
		# Because of the greedy operator *, the unmatched part is on the left (match group 2)
		while [[ $undone_part =~ ${prefix_re1}"$global_prefix"${prefix_re2} ]]; do
			undone_part=${BASH_REMATCH[1]}
			done_part=${ns}${BASH_REMATCH[2]}${done_part}
			line=${undone_part}${done_part}
		done
		#endregion Replace namespace prefixes

		body+=${line}$'\n'
	done

	printdebug 'Function body before returning: %s' "$body"
	local "${retvar:?}" && upvar "$retvar" "$body"
}


__libimport_generate_functions_maps() {
	local -a function_list
	IFS=$'\n' read -r -d '' -a function_list < <(compgen -A function)
	local -A __libimport_FUNCTION_CODE_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP
	local fun line token
	local -a token_list
	local IFS=$' \t\n'
	for fun in "${function_list[@]}"; do
		[[ $fun == "${FUNCNAME[0]}" ]] && continue
		[[ $fun == bash_import ]] && continue
		local -A required_function_set=() required_command_set=()
		local body=''
		while read -r line; do
			if [[ $line =~ $pragma_re ]]; then
				# shellcheck disable=SC2162
				read -d '' -a token_list <<<"${BASH_REMATCH[2]}"
				case ${BASH_REMATCH[1]} in
				require_functions)
					for token in "${token_list[@]}"; do
						required_function_set[$token]=1
					done
					continue
					;;
				require_commands)
					for token in "${token_list[@]}"; do
						required_command_set[$token]=1
					done
					continue
					;;
				esac
			fi
			body+=${line}$'\n'
		done < <(declare -pf "$fun")
		__libimport_FUNCTION_CODE_MAP[$fun]=$body
		__libimport_REQUIRED_FUNCTIONS_MAP[$fun]=${!required_function_set[*]}
		__libimport_REQUIRED_COMMANDS_MAP[$fun]=${!required_command_set[*]}
	done
	declare -p __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP __libimport_FUNCTION_CODE_MAP
}

bash_import() {
	local __libimport_module_path=${1%=*}
	local __libimport_ns=''
	shift
	while ((${#@})); do
		case $1 in
		--)
			shift
			break
			;;
		--prefix | -p)
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

	#region Find library
	local __libimport_import_type __libimport_module_found
	if [[ ${__libimport_module_path} == /* ]]; then
		# absolute path
		__libimport_import_type=absolute
		__FILE__=${__libimport_module_path}
		__libimport_module_found=1
	elif [[ ${__libimport_module_path} == ./* || ${__libimport_module_path} == ../* ]]; then
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

	if ((__libimport_module_found == 1)); then
		if ! __FILE__=$(readlink -e "$__FILE__") || [[ -z $__FILE__ ]]; then
			__libimport_module_found=0
		fi
	fi

	if ((__libimport_module_found == 0)); then
		die "Importing from ${__libimport_import_type} path: '${__libimport_module_path}' not found! (${__FILE__})"
	fi
	unset -v __libimport_import_type __libimport_module_found
	#endregion Find library

	#region Create symbol data structures
	local -A __libimport_FUNCTION_CODE_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP

	eval "$(
		exec bash --noprofile --norc -s <<-EOF
			{
				builtin source "${BASH_SOURCE[0]}"
				builtin source "$__FILE__"
			} > /dev/null
			__libimport_generate_functions_maps
		EOF
	)"
	#endregion Create symbol data structures


	# the import list defaults to all functions
	{
		if (($# == 0)); then # default: import all symbols with prefix __NS__
			local -a __libimport_tmp_list=()
			local __libimport_item
			for __libimport_item in "${!__libimport_FUNCTION_CODE_MAP[@]}"; do
				if [[ ${__libimport_item} == __NS__* ]]; then
					__libimport_tmp_list+=("${__libimport_item}")
				fi
			done
			set -- "${__libimport_tmp_list[@]}"
			#set -- "${!__libimport_FUNCTION_CODE_MAP[@]}"
		else # explicit names: add prefix to all names
			set -- "${@/#/__NS__}"
		fi

	}

	#region Topological sort
	local -A __libimport_adj_map=()
	{ # preparing __libimport_adj_map
		local -A __libimport_tmp_set=()
		local __libimport_item __libimport_item2
		for __libimport_item in "$@"; do
			if [[ -v __libimport_FUNCTION_CODE_MAP[$__libimport_item] ]]; then
				__libimport_tmp_set[$__libimport_item]=1
			else
				printwarn "Missing symbol '$__libimport_item' in module ${__FILE__}"
			fi
		done
		# now __libimport_tmp_set is the set of requested symbols
		while ((${#__libimport_tmp_set[@]} > 0)); do
			for __libimport_item in "${!__libimport_tmp_set[@]}"; do
				__libimport_adj_map[${__libimport_item}]=${__libimport_REQUIRED_FUNCTIONS_MAP[${__libimport_item}]}
				unset -v '__libimport_tmp_set[$__libimport_item]'
				for __libimport_item2 in ${__libimport_REQUIRED_FUNCTIONS_MAP[${__libimport_item}]}; do __libimport_tmp_set[${__libimport_item2}]=1; done
			done
		done
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
					__libimport_tmp_stack+=("${__libimport_item}")
					unset -v '__libimport_adj_map[$__libimport_item]'
				fi
			done
			((${#__libimport_tmp_stack[@]} == 0)) && break
			local __libimport_stack_item=${__libimport_tmp_stack[0]}
			unset -v '__libimport_tmp_stack[0]'
			__libimport_tmp_stack=("${__libimport_tmp_stack[@]}")
			__libimport_sorted_list+=("$__libimport_stack_item")
			for __libimport_item in "${!__libimport_adj_map[@]}"; do
				read -r -d '' -a __libimport_tmp_list <<<"${__libimport_adj_map[${__libimport_item}]}"
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
		declare -p __libimport_FUNCTION_CODE_MAP | logdebug
		local __libimport_item __libimport_item2
		local -A __libimport_commands_set=()
		for __libimport_item in "${__libimport_sorted_list[@]}"; do
			for __libimport_item2 in ${__libimport_REQUIRED_COMMANDS_MAP[${__libimport_item}]}; do
				[[ -v __libimport_commands_set[${__libimport_item2}] ]] && continue
				# accept also aliases and functions as command replacement
				type -at "${__libimport_item2}" &>/dev/null || exit 3
				__libimport_commands_set[${__libimport_item2}]=1
			done
			if [[ -v __libimport_FUNCTION_CODE_MAP[${__libimport_item}] ]]; then
				# shellcheck disable=SC2001
				if declare -F "$__libimport_item" &>/dev/null; then
					printwarn "A function '$__libimport_item' already exists, overwriting."
				fi
				printtrace 'About to eval "%s"' "$__libimport_item"
				printdebug 'Function body before filter: "%s"' "${__libimport_FUNCTION_CODE_MAP[$__libimport_item]}"
				local fun
				retvar=fun __libimport_filter_function_code "$__libimport_ns" <<< "${__libimport_FUNCTION_CODE_MAP[$__libimport_item]}"
				printdebug 'Function body after filter: "%s"' "$fun"
				eval "$fun"
				printtrace 'End of eval "%s"' "$__libimport_item"

				# if [[ -n $STRIP_PRAGMAS ]]; then
				# 	# shellcheck disable=SC2086
				# 	IFS=$' \t\n,:' read -r -d '' -a __libimport_tmp_list <<< "$STRIP_PRAGMAS"
				# 	printf -v __libimport_item2 -- '%s,' "${__libimport_tmp_list[@]}" && __libimport_item2=${__libimport_item2%,} # string join
				# 	printinfo 'Stripping function %s of pragmas %s' "$__libimport_item" "$__libimport_item2"
				# 	strip_function "$__libimport_item" "${__libimport_tmp_list[@]}"
				# fi
			fi
		done
		if [[ -n $DEBUG ]]; then
			IFS= read -r __libimport_item2 < '/proc/sys/kernel/random/uuid'
			__libimport_item2="/tmp/$USER/$$/$__libimport_item2-${__FILE__##*/}"
			mkdir -p "/tmp/$USER/$$/"
			for __libimport_item in "${__libimport_sorted_list[@]}"; do
				declare -f "$__libimport_item"
			done > "$__libimport_item2"
			# shellcheck disable=SC1090
			source "$__libimport_item2"
		fi
		unset -v __libimport_item __libimport_item2 __libimport_commands_set
		unset -v __libimport_sorted_list
	}
	#endregion Importing requested symbols and their dependencies

	unset -v __libimport_module_path __libimport_module_found
	unset -v __libimport_FUNCTION_CODE_MAP __libimport_REQUIRED_FUNCTIONS_MAP __libimport_REQUIRED_COMMANDS_MAP
	unset -v "${!__libimport_@}"
}

@pragma() {
	local name=${1?missing function name}
	local body; body=$(declare -f "$name")
	retvar=body __libimport_filter_function_code <<<"$body"
	eval "$body"
}

#endregion Bashlibs import

pragma() {
	local -i exit_code=$?
	case $1 in
		deprecated)
			printwarn 'Function %s is deprecated' "${FUNCNAME[1]}"
			;;
	esac
	return $exit_code
}

nop() {
	return $?
}

set_exit_code() {
	# shellcheck disable=SC2086
	return ${1:-$?}
}

sink() {
	local buf
	while IFS='' read -r -N512 buf; do
		printf -- '%s' "$buf"
	done
	printf -- '%s' "$buf"
}

upvars() {
	while (( $# )); do
		case $1 in
		-a*)
			# Error checking
			pragma begin safe
			[[ ${1#-a} ]] || die '`%s'\'': missing number specifier' "$1"
			printf %d "${1#-a}" &>/dev/null || die '`%s'\'': invalid number specifier' "$1"
			pragma end
			# Assign array of -aN elements
			# shellcheck disable=SC2086,SC2015,SC1083
			[[ "$2" ]] && unset -v "$2" && eval $2=\(\"\${@:3:${1#-a}}\"\) && shift $((${1#-a} + 2)) || die '`%s'\'': missing argument(s)' "$1${2+ }$2"
			;;
		-A*)
			pragma begin safe
			# Error checking
			[[ ${1#-A} ]] || die '`%s'\'': missing number specifier' "$1"
			printf %d "${1#-A}" &>/dev/null || die '`%s'\'': invalid number specifier' "$1"
			pragma end
			# Assign array of -AN elements
			# shellcheck disable=SC2015
			[[ "$2" ]] && upvar_hash "$2" "${@:3:${1#-A}*2}" && shift $((${1#-A} * 2 + 2)) || die '`%s'\'': missing argument(s)' "$1${2+ }$2"
			;;
		-v)
			# Assign single value
			# shellcheck disable=SC2086,SC2015
			[[ "$2" ]] && unset -v "$2" && eval $2=\"\$3\" && shift 3 || die '`%s'\'': missing argument(s)' "$1"
			;;
		*)
			die '`%s'\'': invalid option' "$1"
			;;
		esac
	done
}

# upvar: {varname} {value}
upvar() {
	if unset -v "${1:?}"; then
		eval "$1=${2@Q}"
	fi
}

# upvar_array: {varname} {values...}
# $1: varname
# $2.. : array values
# It store the values into varname as an array.
# Ex:  local var && upvar_array var 1 2 3
upvar_array() {
	if unset -v "${1:?}"; then
		eval "$1=( \"\${@:2}\" )"
	fi
}


# upvar_hash: {varname} {key1} {value1} {key2} {value2} ...
# Ex:  local var && upvar_hash var ${mymap[@]@K}
upvar_hash() {
	if unset -v "${1:?}"; then
		while (($# > 1)); do
			printf -v "$1[${2@Q}]" -- '%s' "$3"
			set -- "$1" "${@:4}"
		done
		: # set exit code to 0
	fi
}

# # upvar_hash2: {varname} {keys...} {values...}
# upvar_hash2() {
# 	if unset -v "${1:?}"; then
# 		while (($# > 1)); do
# 			eval "$1[${2@Q}]=\${$((($# - 1) / 2 + 2))}"
# 			set -- "$1" "${@:3:($# - 1)/2-1}" "${@:($# - 1)/2+3}"
# 		done
# 		: # set exit code to 0
# 	fi
# }

# upvar_hash2: {varname} {keys...} {values...}
# Ex:  local var && upvar_hash var "${!mymap[@]}" "${mymap[@]}"
upvar_hash2() {
	if unset -v "${1:?}"; then
		while (($# > 1)); do
			printf -v "$1[${2@Q}]" '%s' "${@:($# - 1) / 2 + 2:1}"
			set -- "$1" "${@:3:($# - 1)/2-1}" "${@:($# - 1)/2+3}"
		done
		: # set exit code to 0
	fi
}

die() {
	local -i exit_code=$?
	local fmt=${1:-}
	if [[ $fmt != *'\n' ]]; then
		fmt+='\n'
	fi
	shift
	printfatal 'Exit (%i) at "%s:%i" in %s(): '"${fmt}" $exit_code "$(readlink -e "${BASH_SOURCE[1]}")" "${BASH_LINENO[0]}" "${FUNCNAME[1]}"  "$@"
	if ((exit_code == 0)); then
		exit_code=1
	fi
	exit $exit_code
}



strip_function() {
	local name=${1:?}
	shift
	local IFS=$' \t\n'
	local -i level=0 state=0
	local decl directive line
	decl=$(declare -pf "$name")
	while (( $# > 0 )); do
		directive=$1
		shift
		# TODO: optimize loglevel management
		if [[ $directive == 'loglevel='* ]]; then
			local loglevel=${directive#loglevel=}
			loglevel=${loglevel,,}
			case $loglevel in
				off|0)   ;&
				fatal|1) set -- loglevel=error loglevel=2 "$@" ;&
				error|2) set -- loglevel=warn  loglevel=3 "$@" ;&
				warn|3)  set -- loglevel=info  loglevel=4 "$@" ;&
				info|4)  set -- loglevel=debug loglevel=5 "$@" ;&
				debug|5) set -- loglevel=trace loglevel=6 "$@" ;&
				trace|6) ;;
				*)
			esac
		fi
		decl=$(
			while read -r line; do
				case $state in
					0) # no stripping
						if [[ $line == "pragma begin $directive;" || $line == "pragma begin $directive "* ]]; then
							(( ++level ))
							state=1
							continue
						elif [[ $line == 'end;' || $line == 'end '* ]]; then
							return 1
						elif [[ $line == "pragma $directive;" || $line == "pragma $directive "* ]]; then
							continue
						fi
						printf -- '%s\n' "$line"
						;;
					1) # stripping
						if [[ $line == 'pragma begin '* ]]; then
							(( ++level ))
						elif [[ $line == 'pragma end;' || $line == 'pragma end '* ]]; then
							(( --level ))
							if (( level == 0 )); then
								state=0
								continue
							fi
							if (( level < 0 )); then
								return 1
							fi
						fi
						;;
				esac
			done <<< "$decl"
		)
	done
	eval "$decl"
}

# shopt -s expand_aliases
# alias begincomment="'comment' <<- 'endcomment'"

# begincomment
# Comment example
# xaasa
# endcomment

assert() { return $?; }

#region Loglevels
declare -ga LOGLEVELS=(OFF FATAL ERROR WARN INFO DEBUG TRACE)
declare -ga LOGCOLORS=(0 '1;31' '31' '33' '34' '37' '1')
if [[ -z $LOGDOMAIN ]]; then
	declare -g LOGDOMAIN="${BASH_SOURCE[1]##*/}"
fi

# Ovewritten by set_loglevel()
logfatal() { :; }
logerror() { :; }
logwarn() { :; }
loginfo() { :; }
logdebug() { :; }
logtrace() { :; }
echofatal() { :; }
echoerror() { :; }
echowarn() { :; }
echoinfo() { :; }
echodebug() { :; }
echotrace() { :; }
printfatal() { :; }
printerror() { :; }
printwarn() { :; }
printinfo() { :; }
printdebug() { :; }
printtrace() { :; }

get_loglevel() { :; }

logdomain_filter() {
	local prefix=$1
	# shellcheck disable=SC2034
	local IFS='' LC_ALL=C msg
	while read -r msg; do
		printf -- "${prefix}"'%s\n' "$msg"
	done
}

loglevel_filter() {
	local -r prefix=$1
	# shellcheck disable=SC2034
	local IFS='' LC_ALL=C msg
	while read -r msg; do
		printf -- "${prefix}"'%s\n' "$msg"
	done
}

generate_log_functions() {
	local -i loglevel=${1:?}
	local -a suffixes=("${LOGLEVELS[@],,}")
	unset 'suffixes[0]'
	local -i level
	local suffix
	local level_name
	local color reset
	local template

	if [[ -z $LOGCOLOR ]]; then
		local -i LOGCOLOR=1
	fi

	if [[ -z $LOGSINK ]]; then
		local LOGSINK='1>&2'
	fi

	for level in "${!suffixes[@]}"; do
		suffix=${suffixes[$level]}
		level_name="${LOGLEVELS[$level]}"

		if ((LOGCOLOR == 1)); then
			color="${LOGCOLORS[$level]}"
			[[ -z $color ]] && color='0'
			color="\e[${color}m"
			reset="\e[0m"
		else
			color=''
			reset=''
		fi

		if ((loglevel >= level)); then
			template=$(
				cat <<-EOF
					log${suffix}()   {
						local -ir x=\$?
						logdomain_filter "${color}"\${LOGDOMAIN@Q}"${reset}:" | loglevel_filter "${color}${level_name}${reset}:" $LOGSINK
						return \$x
					}
					echo${suffix}()  {
						local -ir x=\$?
						printf '%b:%s\n' "${color}"\${LOGDOMAIN@Q}"${reset}" "\$*" | loglevel_filter "${color}${level_name}${reset}:" $LOGSINK
						return \$x
					}
					print${suffix}() {
						local -ir x=\$?; local fmt="\$1"; shift
						printf "${color}"\${LOGDOMAIN@Q}"${reset}:\$fmt\n" "\$@" | loglevel_filter "${color}${level_name}${reset}:" $LOGSINK
						return \$x
					}
				EOF
			)
			eval "$template"
		else
			template=$(
				cat <<-EOF
					log${suffix}()   { declare -ir x=\$?; while IFS= read -r -N512 _; do :; done; return \$x; }
					echo${suffix}()  { return \$?; }
					print${suffix}() { return \$?; }
				EOF
			)
		fi
		eval "$template"
		# shellcheck disable=SC2034
		template=$(
			cat <<-EOF
				get_loglevel() {
					prinf -v "\${retvar}" -- '%i' $loglevel
				}
			EOF
		)
		eval "$template"
	done
}

set_loglevel() {
	declare loglevel="$1"
	declare -i i err=0
	declare -ir default_loglevel=4

	if [[ $loglevel =~ ^[0-9]+$ ]]; then
		if ((loglevel < 0)); then
			loglevel=0
			err=1
		elif ((loglevel >= ${#LOGLEVELS[@]})); then
			loglevel=$((${#LOGLEVELS[@]} - 1))
			err=2
		fi
	else
		while :; do
			for ((i = 0; i < ${#LOGLEVELS[@]}; ++i)); do
				if [[ ${loglevel,,} == "${LOGLEVELS[$i],,}" ]]; then
					loglevel=$i
					break 2
				fi
			done
			loglevel=$default_loglevel
			err=3
			break
		done
	fi
	generate_log_functions $loglevel
	return $err
}

set_loglevel 4

#endregion Loglevels
