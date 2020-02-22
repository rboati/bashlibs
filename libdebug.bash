


declare -gA __NS__BREAKPOINTS=()
declare -ga __NS__WATCHES=()
declare -g  __NS__STEPMODE=1
declare -ga __NS____CALLER_ARGS__
declare -ga __NS____CALLER_LOCALS__
declare -ga __NS____CALLER_LEVEL__
declare -gA __NS__DEBUGGER_PROPERTIES=(
	[locals.auto]=0
	[list.auto]=1
	[list.context]=1
	[stack.auto]=1
	[watch.auto]=0
	[color]=1
	[color.prompt]='33'
	[color.prompt.off]='39'
	[color.line]='34'
	[color.line.off]='39'
	[color.title]='1'
	[color.title.off]='22'
)

__NS__set_debugger_trap() {
	set -o functrace
	trap '__NS____CALLER_ARGS__=( "$@" ); __NS____CALLER_LOCALS__="$(local 2> /dev/null)"; __NS__debugger' DEBUG
}

__NS__unset_debugger_trap() {
	trap '' DEBUG
	set +o functrace
}

__NS__set_breakpoint() {
	local LOC="$1"
	local TEST="$2"
	local -i LINE="${LOC##*:}"
	local SOURCE="${LOC%${LINE}}"; SOURCE="${SOURCE%:}"
	if [[ -z $SOURCE ]]; then
		SOURCE="${BASH_SOURCE[1]}"
	fi
	SOURCE=$(readlink -m "$SOURCE")
	if [[ -z $TEST ]]; then
		TEST=':'
	fi
	__NS__BREAKPOINTS[$SOURCE:$LINE]="$TEST"
}

__NS__unset_breakpoint() {
	local LOC="$1"
	local TEST="$2"
	local -i LINE="${LOC##*:}"
	local SOURCE="${LOC%${LINE}}"; SOURCE="${SOURCE%:}"
	if [[ -z $SOURCE ]]; then
		SOURCE="${BASH_SOURCE[1]}"
	fi
	SOURCE="$(readlink -m "$SOURCE")"
	unset __NS__BREAKPOINTS[$SOURCE:$LINE]
}

__NS__get_breakpoint_list() {
	local i
	for i in "${!__NS__BREAKPOINTS[@]}"; do
		printf '[%s] = "%s"\n' "$(realpath --relative-to="$PWD" "$i")" "${__NS__BREAKPOINTS[$i]}"
	done
}

__NS__add_watch() {
	local EXPR="$@"
	__NS__WATCHES+=( "$EXPR" )
}

__NS__delete_watch() {
	local INDEX="$1"
	unset __NS__WATCHES[$INDEX]
}

__NS__set_debugger_properties() {
	local PROP="$1"
	local VAL="$2"
	if [[ -z $PROP || -z ${__NS__DEBUGGER_PROPERTIES[$PROP]:+test} || -z ${VAL:+test} ]]; then
		return
	fi
	__NS__DEBUGGER_PROPERTIES[$PROP]="$VAL"
}

__NS__get_debugger_properties() {
	local PROP="$1"
	if [[ -z $PROP ]]; then
		for PROP in  "${!__NS__DEBUGGER_PROPERTIES[@]}"; do
			printf '%20s = "%s"\n' "$PROP" "${__NS__DEBUGGER_PROPERTIES[$PROP]}"
		done | sort
		return
	fi
	if [[ -z ${__NS__DEBUGGER_PROPERTIES[$PROP]:+test} ]]; then
		return
	fi
	printf '%20s = "%s"\n' "$PROP" "${__NS__DEBUGGER_PROPERTIES[$PROP]}"
}

__NS__debugger_output_filter() {
	local PROMPT_COLOR_ON='' PROMPT_COLOR_OFF=''
	if (( ${__NS__DEBUGGER_PROPERTIES[color]} == 1 )); then
		PROMPT_COLOR_ON="\e[${__NS__DEBUGGER_PROPERTIES[color.prompt]}m"
		PROMPT_COLOR_OFF="\e[${__NS__DEBUGGER_PROPERTIES[color.prompt.off]:-0}m"
	fi
	while IFS='' read -r MSG; do
		printf '%bDEBUG:%b %s\n' "${PROMPT_COLOR_ON}" "${PROMPT_COLOR_OFF}" "$MSG"
	done
}

__NS__call_stack() {
	local -i i initial=${1:-0}
	for (( i=initial; i < (${#FUNCNAME[@]}-1); ++i )); do
		echo -n "$((i-initial)): "
		caller "$i"
	done
}

__NS__list_source_code() {
	local -i i initial=${1:-0}
	local SOURCE="${BASH_SOURCE[$initial + 1]}"
	SOURCE="$(readlink -m "$SOURCE")"
	local -i LINE="${BASH_LINENO[$initial]}"
	local -i CONTEXT="${__NS__DEBUGGER_PROPERTIES[list.context]}"
	local OUT
	local LINE_COLOR_ON='' LINE_COLOR_OFF=''
	if (( ${__NS__DEBUGGER_PROPERTIES[color]} == 1 )); then
		LINE_COLOR_ON="$(__NS__get_debugger_color line)"
		LINE_COLOR_OFF="$(__NS__get_debugger_color line.off)"
	fi
	{
		for (( i=(LINE-CONTEXT); i <= (LINE+CONTEXT); ++i )); do
			OUT="$(sed "${i}q;d" "$SOURCE")"
			[[ $? != 0 ]] && OUT="..."
			OUT="${OUT%$'\n'}"
			if (( i == LINE )); then
				printf '%b%5s> %s%b\n' "${LINE_COLOR_ON}" "$((i))" "$OUT" "${LINE_COLOR_OFF}"
			else
				printf '%5s: %s\n' "$((i))" "$OUT"
			fi
		done
	} 2> /dev/null
}

__NS__get_debugger_color() {
	local PROP="$1"
	if (( ${__NS__DEBUGGER_PROPERTIES[color]} == 1 )); then
		printf '%b' "\e[${__NS__DEBUGGER_PROPERTIES[color.${PROP}]:-0}m"
	fi
}

__NS__debugger() {
	{
		local -i __NS____EXITCODE__=$?
		if (( __NS__STEPMODE == 0 )); then
			if (( ${#__NS__BREAKPOINTS[@]} == 0 )); then
				return $__NS____EXITCODE__
			fi
			local __NS____BP__
			__NS____BP__="${BASH_SOURCE[1]}"
			__NS____BP__="$(readlink -m "$__NS____BP__")"
			__NS____BP__="${__NS____BP__}:${BASH_LINENO[0]}"
			__NS____BP__="${__NS__BREAKPOINTS[$__NS____BP__]}"
			if [[ -z $__NS____BP__ ]]; then
				return $__NS____EXITCODE__
			fi
			if ! eval "$__NS____BP__"; then
				return $__NS____EXITCODE__
			fi
			unset __NS____BP__
		fi

		__NS____CALLER_LOCALS__=( $( echo "$__NS____CALLER_LOCALS__" | while IFS="=" read -r __NS____i__ x; do echo "$__NS____i__"; done) )
		local IFS
		{
			if [[ ${__NS__DEBUGGER_PROPERTIES[stack.auto]} == 1 ]]; then
				printf '%bCall tree:%b\n' "$(__NS__get_debugger_color title)" "$(__NS__get_debugger_color title.off)"
				__NS__call_stack 1
			fi

			if [[ ${__NS__DEBUGGER_PROPERTIES[watch.auto]} == 1 ]]; then
				printf '%bWatches:%b\n' "$(__NS__get_debugger_color title)" "$(__NS__get_debugger_color title.off)"
				local -i __NS____i__
				for __NS____i__ in "${!__NS__WATCHES[@]}"; do
					printf '[%d] %s = %s\n' "$__NS____i__" "${__NS__WATCHES[$__NS____i__]}" "$(eval "echo ${__NS__WATCHES[$__NS____i__]}")"
				done
				unset __NS____i__
			fi

			if [[ ${__NS__DEBUGGER_PROPERTIES[locals.auto]} == 1 ]]; then
				printf '%bLocals:%b\n' "$(__NS__get_debugger_color title)" "$(__NS__get_debugger_color title.off)"
				if (( ${#__NS____CALLER_LOCALS__[@]} > 0 )); then
					declare -p "${__NS____CALLER_LOCALS__[@]}"
				fi
			fi

			if [[ ${__NS__DEBUGGER_PROPERTIES[list.auto]} == 1 ]]; then
				printf '%bList:%b\n' "$(__NS__get_debugger_color title)" "$(__NS__get_debugger_color title.off)"
				__NS__list_source_code 1
			fi
		} | __NS__debugger_output_filter

		local HISTFILE="$HOME/.bash_debugger"
		local HISTCONTROL="ignorebuth:erasedups"
		history -c
		history -r
		local -a __NS____REPL__
		while read -r -e -p"$(__NS__get_debugger_color prompt)$([[ $- == *T* ]] && echo "STEP" || echo "NEXT")>$(__NS__get_debugger_color prompt.off) " -a __NS____REPL__; do
			case "${__NS____REPL__[0]}" in
				'\break'|'\bp')
					if (( ${#__NS____REPL__[@]} > 1 )); then
						local -i LINE="${__NS____REPL__[1]##*:}"
						local SOURCE="${__NS____REPL__[1]%${LINE}}"; SOURCE="${SOURCE%:}"
						if [[ -z $SOURCE ]]; then
							SOURCE="${BASH_SOURCE[1]}"
						fi
						__NS__set_breakpoint "$SOURCE:$LINE"
						unset LINE SOURCE
					else
						__NS__get_breakpoint_list | __NS__debugger_output_filter
					fi
					history -s "${__NS____REPL__[@]}"
					;;
				'\quit')
					__NS__unset_debugger_trap
					__NS__STEPMODE=0
					history -s "${__NS____REPL__[@]}"
					history -w
					echo "QUIT"  | __NS__debugger_output_filter
					return $__NS____EXITCODE__
					;;
				'\cont')
					__NS__STEPMODE=0
					set -o functrace
					history -s "${__NS____REPL__[@]}"
					history -w
					echo "CONT"  | __NS__debugger_output_filter
					return $__NS____EXITCODE__
					;;
				'\exit')
					history -s "${__NS____REPL__[@]}"
					history -w
					exit "$@"
					;;
				'\list')
					__NS__list_source_code 1 | __NS__debugger_output_filter
					history -s "${__NS____REPL__[@]}"
					;;
				'\step')
					set -o functrace
					history -s "${__NS____REPL__[@]}"
					__NS__STEPMODE=1
					history -w
					{
						[[ $- == *T* ]] && echo "STEP" || echo "NEXT"
					} | __NS__debugger_output_filter
					return $__NS____EXITCODE__
					;;
				'\next')
					set +o functrace
					history -s "${__NS____REPL__[@]}"
					__NS__STEPMODE=1
					history -w
					{
						[[ $- == *T* ]] && echo "STEP" || echo "NEXT"
					} | __NS__debugger_output_filter
					return $__NS____EXITCODE__
					;;
				'\stack')
					__NS__call_stack 1 | __NS__debugger_output_filter
					history -s "${__NS____REPL__[@]}"
					;;
				'\locals')
					if (( ${#__NS____CALLER_LOCALS__[@]} > 0 )); then
						declare -p "${__NS____CALLER_LOCALS__[@]}"
					fi | __NS__debugger_output_filter
					history -s "${__NS____REPL__[@]}"
					;;
				'\watch')
					if (( ${#__NS____REPL__[@]} > 1 )); then
						__NS__add_watch "${__NS____REPL__[@]:1}"
					else
						local -i __NS____i__
						for __NS____i__ in "${!__NS__WATCHES[@]}"; do
							printf '[%d] %s = %s\n' "$__NS____i__" "${__NS__WATCHES[$__NS____i__]}" "$(eval "echo ${__NS__WATCHES[$__NS____i__]}")"
						done | __NS__debugger_output_filter
						unset __NS____i__
					fi
					history -s "${__NS____REPL__[@]}"
					;;
				'\delete')
					case "${__NS____REPL__[1]}" in
						'breakpoint'|'bp')
							if (( ${#__NS____REPL__[@]} > 2 )); then
								local -i LINE="${__NS____REPL__[2]##*:}"
								local SOURCE="${__NS____REPL__[2]%${LINE}}"; SOURCE="${SOURCE%:}"
								if [[ -z $SOURCE ]]; then
									SOURCE="${BASH_SOURCE[1]}"
								fi
								__NS__unset_breakpoint "$SOURCE:$LINE"
								unset LINE SOURCE
							else
								unset __NS__BREAKPOINTS[@]
							fi
							;;
						'watch')
							if (( ${#__NS____REPL__[@]} > 2 )); then
								__NS__delete_watch "${__NS____REPL__[@]:2}"
							else
								__NS__WATCHES=()
							fi
							;;
						'')
							echo "Missing argument" | __NS__debugger_output_filter
							;;
						*)
							echo "Unknown argument: ${__NS____REPL__[1]}" | __NS__debugger_output_filter
							;;
					esac
					history -s "${__NS____REPL__[@]}"
					;;
				'\set')
					if [[ -z ${__NS____REPL__[1]:+test} ]]; then
						__NS__get_debugger_properties | __NS__debugger_output_filter
					elif [[ -z ${__NS____REPL__[2]:+test} ]]; then
						__NS__get_debugger_properties "${__NS____REPL__[1]}" | __NS__debugger_output_filter
					else
						__NS__set_debugger_properties "${__NS____REPL__[1]}" "${__NS____REPL__[2]}"
					fi
					history -s "${__NS____REPL__[@]}"
					;;
				'\help')
					history -s "${__NS____REPL__[@]}"
					;;
				'\'*)
					echo "Unknown command: ${__NS____REPL__[0]}" | __NS__debugger_output_filter
					;;
				*)
					set -- "${__NS____CALLER_ARGS__[@]}"
					eval "${__NS____REPL__[@]}"
					history -s "${__NS____REPL__[@]}"
					;;
			esac
		done
		echo
		__NS__STEPMODE=1
		history -w
		{
			[[ $- == *T* ]] && echo "STEP" || echo "NEXT"
		} | __NS__debugger_output_filter
		return $__NS____EXITCODE__
	} <&10 >&11 >&12 # set stdin, stdout, stderr
}

exec 10<&0 11>&1 12>&2 # save stdin, stdout, stderr


