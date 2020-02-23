


declare -gA __NS__BREAKPOINTS=()
declare -ga __NS__WATCHPOINTS=()
declare -ga __NS__WATCHES=()
declare -g  __NS__STEPMODE=1
declare -ga __NS__STEPMODE_NAMES=( CONT STEP NEXT RETURN )
declare -gi __NS__RETURN_BREAK=0
declare -ga __NS____CALLER_ARGS__
declare -ga __NS____CALLER_LOCALS__
declare -ga __NS____CALLER_LEVEL__
declare -gA __NS__DEBUGGER_PROPERTIES=(
	[auto]="stack list locals watch"
	[locals.auto]=0
	[list.auto]=1
	[list.context]=1
	[stack.auto]=1
	[watch.auto]=0
	[color]=1
	[color.default]='2'
	[color.default.off]='22'
	[color.prompt]='33'
	[color.prompt.off]='39'
	[color.line]='34'
	[color.line.off]='39'
	[color.title]='1'
	[color.title.off]='22'
	[color.value]='34'
	[color.value.off]='39'
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

__NS__set_debugger_property() {
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
		PROMPT_COLOR_ON="$(__NS__get_debugger_color prompt)"
		PROMPT_COLOR_OFF="$(__NS__get_debugger_color_off prompt)"
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

__NS__call_stack_level() {
	local -i i
	for (( i=0; i < (${#FUNCNAME[@]}-1); ++i )); do
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
	if (( ${__NS__DEBUGGER_PROPERTIES[color]} != 1 )); then
		return
	fi
	local PROP="$1"
	if [[ -z ${__NS__DEBUGGER_PROPERTIES[color.${PROP}]} ]]; then
		return
	fi
	printf '%b' "\e[${__NS__DEBUGGER_PROPERTIES[color.${PROP}]}m"
}

__NS__get_debugger_color_off() {
	if (( ${__NS__DEBUGGER_PROPERTIES[color]} != 1 )); then
		return
	fi
	local PROP="$1"
	if [[ -z ${__NS__DEBUGGER_PROPERTIES[color.${PROP}]} ]]; then
		return
	fi
	local ansi=''
	if [[ -z ${__NS__DEBUGGER_PROPERTIES[color.${PROP}.off]} ]]; then
		ansi+='0;'
	else
		ansi+="${__NS__DEBUGGER_PROPERTIES[color.${PROP}.off]};"
	fi
	if [[ $PROP != default && -n ${__NS__DEBUGGER_PROPERTIES[color.default]} ]]; then
		ansi+="${__NS__DEBUGGER_PROPERTIES[color.default]};"
	fi
	printf '%b' "\e[${ansi%;}m"
}


__NS__debugger() {
	{
		local -i __NS____EXITCODE__=$?
		local -i __NS____BREAK__=0
		local IFS=$' \t\n'
		set -- "${__NS____CALLER_ARGS__[@]}"

		if (( __NS__STEPMODE == 1 )); then
			__NS____BREAK__=1
		elif (( __NS__STEPMODE == 2 )); then
			if (( __NS__RETURN_BREAK >= ${#FUNCNAME[@]} )); then
				__NS____BREAK__=1
				__NS__RETURN_BREAK=0
			fi
		elif (( __NS__STEPMODE == 3 )); then
			if (( __NS__RETURN_BREAK > ${#FUNCNAME[@]} )); then
				__NS____BREAK__=1
				__NS__RETURN_BREAK=0
			fi
		fi

		if (( __NS____BREAK__ == 0 && ${#__NS__BREAKPOINTS[@]} != 0 )); then
			local __NS____BP__
			__NS____BP__="${BASH_SOURCE[1]}"
			__NS____BP__="$(readlink -m "$__NS____BP__")"
			__NS____BP__="${__NS____BP__}:${BASH_LINENO[0]}"
			__NS____BP__="${__NS__BREAKPOINTS[$__NS____BP__]}"
			if [[ -n $__NS____BP__ ]]; then
				if eval "$__NS____BP__"; then
					__NS____BREAK__=1
					echo "Hit breakpoint"
				fi
			fi
			unset __NS____BP__
		fi

		if (( __NS____BREAK__ == 0 && ${#__NS__WATCHPOINTS[@]} != 0 )); then
			local __NS____BP__
			for __NS____BP__ in "${__NS__WATCHPOINTS[@]}"; do
				if eval "$__NS____BP__"; then
					__NS____BREAK__=1
					echo "Hit watchpoint"
					break
				fi
			done
			unset __NS____BP__
		fi

		if (( __NS____BREAK__ == 0 )); then
			return $__NS____EXITCODE__
		fi

		unset __NS____BREAK__

		__NS____CALLER_LOCALS__=( $( echo "$__NS____CALLER_LOCALS__" | while IFS="=" read -r __NS____i__ x; do echo "$__NS____i__"; done) )

		__NS__get_debugger_color default

		local HISTFILE="$HOME/.bash_debugger"
		local HISTCONTROL="ignoreboth:erasedups"
		history -c
		history -r
		local -a __NS____REPL__
		while :; do # AUTO DISPLAY LOOP
			local __NS____AUTO__
			for __NS____AUTO__ in ${__NS__DEBUGGER_PROPERTIES[auto]}; do
				case "$__NS____AUTO__" in
					stack)
						if [[ ${__NS__DEBUGGER_PROPERTIES[stack.auto]} == 1 ]]; then
							printf '%bCall tree:%b\n' "$(__NS__get_debugger_color title)" "$(__NS__get_debugger_color_off title)"
							__NS__call_stack 1
						fi
						;;
					list)
						if [[ ${__NS__DEBUGGER_PROPERTIES[list.auto]} == 1 ]]; then
							printf '%bListing %s:%b\n' "$(__NS__get_debugger_color title)" "$(caller 0 | while read -r a b c; do echo "$b() in $c";done;)" "$(__NS__get_debugger_color_off title)"
							__NS__list_source_code 1
						fi
						;;
					locals)
						if [[ ${__NS__DEBUGGER_PROPERTIES[locals.auto]} == 1 ]]; then
							printf '%bLocals:%b\n' "$(__NS__get_debugger_color title)" "$(__NS__get_debugger_color_off title)"
							local -i __NS____i__=1
							local __NS____ARG__
							for __NS____ARG__ in "$@"; do
								printf '$%s="%s"\n'  $((__NS____i__++)) "$__NS____ARG__"
							done
							unset __NS____i__ __NS____ARG__
							if (( ${#__NS____CALLER_LOCALS__[@]} > 0 )); then
								declare -p "${__NS____CALLER_LOCALS__[@]}"
							fi
						fi
						;;
					watch)
						if [[ ${__NS__DEBUGGER_PROPERTIES[watch.auto]} == 1 ]]; then
							printf '%bWatches:%b\n' "$(__NS__get_debugger_color title)" "$(__NS__get_debugger_color_off title)"
							local -i __NS____i__
							for __NS____i__ in "${!__NS__WATCHES[@]}"; do
								printf '[%d] %s = %s\n' "$__NS____i__" "${__NS__WATCHES[$__NS____i__]}" "$(eval "echo ${__NS__WATCHES[$__NS____i__]}")"
							done
							unset __NS____i__
						fi
						;;
				esac
			done
			unset __NS____AUTO__

			while :; do # REPL LOOP
				while read -r -e -p"$(__NS__get_debugger_color prompt)${__NS__STEPMODE_NAMES[__NS__STEPMODE]}>$(__NS__get_debugger_color_off prompt) " -a __NS____REPL__; do
					case "${__NS____REPL__[0]}" in
						'\'*) ;;
						'') continue 3;;
						*) ;;
					esac
					break
				done # READ LOOP

				if [[ -z $__NS____REPL__ ]]; then
					case "$__NS__STEPMODE" in
						0) __NS____REPL__=( '\cont'   );;
						1) __NS____REPL__=( '\step'   );;
						2) __NS____REPL__=( '\next'   );;
						3) __NS____REPL__=( '\return' );;
					esac
					echo "${__NS____REPL__[0]}"
				fi

				case "${__NS____REPL__[0]}" in
					'\exit')
						history -s "${__NS____REPL__[@]}"
						history -w
						exit "${__NS____REPL__[1]}"
						;;
					'\quit')
						__NS__unset_debugger_trap
						__NS__STEPMODE=0
						break
						;;
					'\cont')
						__NS__STEPMODE=0
						break
						;;
					'\step')
						__NS__STEPMODE=1
						break
						;;
					'\next')
						__NS__STEPMODE=2
						__NS__RETURN_BREAK="${#FUNCNAME[@]}"
						break
						;;
					'\return')
						__NS__STEPMODE=3
						(( ${#FUNCNAME[@]} <= 2 )) && continue
						__NS__RETURN_BREAK="${#FUNCNAME[@]}"
						break
						;;
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
							__NS__get_breakpoint_list
						fi
						;;
					'\list')
						__NS__list_source_code 1
						;;
					'\stack')
						__NS__call_stack 1
						;;
					'\locals')
						local -i __NS____i__=1
						local __NS____ARG__
						for __NS____ARG__ in "$@"; do
							printf '$%s="%s"\n'  $((__NS____i__++)) "$__NS____ARG__"
						done
						unset __NS____i__ __NS____ARG__
						if (( ${#__NS____CALLER_LOCALS__[@]} > 0 )); then
							declare -p "${__NS____CALLER_LOCALS__[@]}"
						fi
						;;
					'\watch')
						if (( ${#__NS____REPL__[@]} > 1 )); then
							__NS__add_watch "${__NS____REPL__[@]:1}"
						else
							local -i __NS____i__
							for __NS____i__ in "${!__NS__WATCHES[@]}"; do
								printf '[%d] %s = %s\n' "$__NS____i__" "${__NS__WATCHES[$__NS____i__]}" "$(eval "echo ${__NS__WATCHES[$__NS____i__]}")"
							done
							unset __NS____i__
						fi
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
								echo "Missing argument"
								;;
							*)
								echo "Unknown argument: ${__NS____REPL__[1]}"
								;;
						esac
						;;
					'\set')
						if [[ -z ${__NS____REPL__[1]:+test} ]]; then
							__NS__get_debugger_properties
						elif [[ -z ${__NS____REPL__[2]:+test} ]]; then
							__NS__get_debugger_properties "${__NS____REPL__[1]}"
						else
							__NS__set_debugger_property "${__NS____REPL__[1]}" "${__NS____REPL__[2]}"
						fi
						;;
					'\help'|'\?')
						cat <<- EOF
							| \help | \?
							|     Show this help.
							| \exit [n]
							|     Exit program execution.
							| \quit
							|     Quit debugger, the program execution continues normally.
							| \cont
							|     Continue until next breakpoint.
							| \step
							|     Step into current command, if possible.
							| \next
							|     Execute current command and stop in the next line, if no breakpoints are
							|     hit before.
							| \return
							|     Return to the caller, if no breakpoints are hit before.
							| \break | \bp  [[[sourcefile:]line] [expr]]
							|     Set a breakpoint in file 'sourcefile' at line 'line', eventually adding
							|     an expression to be evaluated as a condition.
							|     If no paramater is given, display breakpoint list.
							| \list
							|     Show source code ad current line. See \set list.context for setting
							|     context lines.
							| \stack
							|     Show call stack.
							| \locals
							|     Show arguments and locals of current function.
							| \watch [expr]
							|     If an expression 'expr' is given, add 'expr' to the list of watches.
							|     Otherwise show watch list.
							| \delete breakpoint [location] | \delete bp [location]
							|     Delete all breakpoints or the breakpoint at 'location' if given,
							| \delete watch [n]
							|     Delete all watches or the watch at index 'n' if given,
							| \set [option [value]]
							|     If no option is given show all options.
							|     If a 'value' is given set 'option' to 'value', otherwise show the value
							|     of specified option.
						EOF
						;;
					'\'*)
						echo "Unknown command: ${__NS____REPL__[0]}"
						continue # skip saving history
						;;
					'')
						continue # skip saving history
						;;
					*)
						eval "${__NS____REPL__[@]}" >&11
						;;
				esac

				history -s "${__NS____REPL__[@]}"
				history -w
			done # REPL LOOP
			history -s "${__NS____REPL__[@]}"
			history -w
			__NS__get_debugger_color_off default
			return $__NS____EXITCODE__
		done # AUTO DISPLAY LOOP
	} 0<&10 1>&11 2>&12 # set stdin, stdout, stderr
}

exec 10<&0 11>&1 12>&2 # save stdin, stdout, stderr


