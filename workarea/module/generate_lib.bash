#!/bin/bash







__generate_module() {
	local -a functions
	IFS=$'\n' read -r -d '' -a functions < <(compgen -A function)
	local -A __FUNCTIONS_MAP__
	local -A __REQUIRED_FUNCTIONS_MAP__
	local -A __REQUIRED_COMMANDS_MAP__
	local fun
	local item
	local IFS=$' \t\n'
	for fun in "${functions[@]}"; do
		[[ $fun == "${FUNCNAME[0]}" ]] && continue
		local -A required_functions=() required_commands=()
		local body
		while read -r line; do
			if [[ $line =~ ^[[:space:]]*'.require_'([_[:alnum:]]+)[[:space:]]+(.*)\;$ ]]; then
				case ${BASH_REMATCH[1]} in
					functions)
						# shellcheck disable=SC2162
						read -d '' -a tmp_list <<< "${BASH_REMATCH[2]}"
						for item in "${tmp_list[@]}"; do
							required_functions[$item]=1
						done
					;;
					commands)
						# shellcheck disable=SC2162
						read -d '' -a tmp_list <<< "${BASH_REMATCH[2]}"
						for item in "${tmp_list[@]}"; do
							required_commands[${item@Q}]=1
						done
					;;
				esac
				continue
			fi
			body+=$line$'\n'
		done < <(declare -pf "$fun")
		__FUNCTIONS_MAP__[$fun]=$body
		__REQUIRED_FUNCTIONS_MAP__[$fun]=${!required_functions[*]}
		__REQUIRED_COMMANDS_MAP__[$fun]=${!required_commands[*]}
	done
	declare -p __REQUIRED_FUNCTIONS_MAP__ __REQUIRED_COMMANDS_MAP__ __FUNCTIONS_MAP__

}
export -f __generate_module

main() {
	local module_path=${1%=*}
	local ns=${1##*=}

	shift
	local IFS=$' \t\n'

	local -A __FUNCTIONS_MAP__
	local -A __REQUIRED_FUNCTIONS_MAP__
	local -A __REQUIRED_COMMANDS_MAP__

	{ # create symbols data structures
		local module_def
		module_def=$(
			bash --norc <<- EOF
				bash_import() { :; }
				\\source "$module_path" &> /dev/null
				unset -v -f bash_import
				__generate_module
			EOF
		)

		eval "$module_def"
		unset -v module_def
	}

	# the import list defaults to all functions
	if (( $# == 0 )); then
		set -- "${!__FUNCTIONS_MAP__[@]}"
	fi

	{ # check non-existance
		local item
		for item in "$@"; do
			[[ ! -v "${__FUNCTIONS_MAP__[$item]}" ]] ||	exit 1
		done
		unset -v item
	}

	local -A adj_map=()
	{ # preparing adj_map
		local -A tmp_set=()
		local item item2
		for item in "$@"; do
			[[ -v __FUNCTIONS_MAP__[$item] ]] || exit 1
			tmp_set[$item]=1
		done
		while (( ${#tmp_set[@]} > 0 )); do
			for item in "${!tmp_set[@]}"; do
				adj_map[$item]=${__REQUIRED_FUNCTIONS_MAP__[$item]}
				for item2 in ${__REQUIRED_FUNCTIONS_MAP__[$item]}; do tmp_set[$item2]=1; done
			done
		done
		[[ -v '__FUNCTIONS_MAP__[__init__]' ]] && adj_map[__init__]=${__FUNCTIONS_MAP__[__init__]}
		unset -v tmp_set item item2
	}

	local -a sorted_list=()
	{ # topological sort
		local -a stack=() tmp_list
		local -i i
		local item

		while :; do
			for item in "${!adj_map[@]}"; do
				if [[ ! -v adj_map[$item] || ${adj_map[$item]} == '' ]]; then
					stack+=( "$item" )
					unset -v "adj_map[$item]"
				fi
			done
			(( ${#stack[@]} == 0 )) && break
			local stack_item=${stack[0]} ; unset -v 'stack[0]'; stack=( "${stack[@]}" )
			sorted_list+=( "$stack_item" )
			for item in "${!adj_map[@]}"; do
				read -r -d '' -a tmp_list <<< "${adj_map[$item]}"
				for i in "${!tmp_list[@]}"; do
					if [[ ${tmp_list[i]} == "$stack_item" ]]; then
						unset -v 'tmp_list[i]'
					fi
				done
				adj_map[$item]=${tmp_list[*]}
			done
		done
		unset -v stack tmp_list i item

	}

	{ # finally importing requested symbols and their dependencies
		local item item2
		local -A checked_commands_set=()
		for item in "${!sorted_list[@]}"; do
			for item2 in ${__REQUIRED_COMMANDS_MAP__[$item]}; do
				[[ -v checked_commands_set[$item2] ]] && continue
				# accept also aliases and functions as command replacement
				type -at "$item2" &> /dev/null || exit 3
				checked_commands_set[$item2]=1
			done
			[[ ! -v "${__FUNCTIONS_MAP__[$item]}" ]] &&	eval "${__FUNCTIONS_MAP__[$item]}"
		done
		unset -v item item2 checked_commands_set
	}
}

main "$@"