

__NS__initialize_libhsm() {
	declare -gri __NS__SIG_EMPTY=-4
	declare -gri __NS__SIG_INIT=-3
	declare -gri __NS__SIG_EXIT=-2
	declare -gri __NS__SIG_ENTRY=-1

	declare -gri __NS__RET_IGNORED=0
	declare -gri __NS__RET_PARENT=1
	declare -gri __NS__RET_HANDLED=2
	declare -gri __NS__RET_TRAN=3
}

__NS__state_TOP_STATE() {
	return $__NS__RET_IGNORED
}

__NS__state_TERMINATE_STATE() {
	return $__NS__RET_HANDLED
}



__NS__dispatch_event() {
	pragma local_prefix x_
	# In this function, names are messy on purpose to avoid user's names collisions
	local x_s
	local x_t=${__NS__STATE:?} # save current state
	local -i x_r x_ip x_iq

	while :; do # send the event to the currente state, eventually descending into parents
		x_s=$__NS__STATE
		"__NS__state_$x_s" "$@"
		x_r=$?
		(( x_r != __NS__RET_PARENT )) && break
	done

	if (( x_r != __NS__RET_TRAN )); then
		__NS__STATE=$x_t # restore current state
		return
	fi

	# we have a transition
	# here __NS__STATE is the destination state of last transition, as requested by the user
	# here x_t is the original source state
	# here x_s is the source state of last transition

	x_ip=-1
	__NS__HSM_PATH[0]=$__NS__STATE
	__NS__HSM_PATH[1]=$x_t

	while [[ $x_t != "$x_s" ]]; do
		"__NS__state_$x_t" $__NS__SIG_EXIT
		if (( $? == __NS__RET_HANDLED )); then
			"__NS__state_$x_t" $__NS__SIG_EMPTY
		fi
		x_t=$__NS__STATE
	done
	x_t=${__NS__HSM_PATH[0]}

	if [[ $x_s == "$x_t" ]]; then
		"__NS__state_$x_s" $__NS__SIG_EXIT
		x_ip=0
	else
		"__NS__state_$x_t" $__NS__SIG_EMPTY
		x_t=$__NS__STATE;
		if [[ $x_s == "$x_t" ]]; then
			x_ip=0
		else
			"__NS__state_$x_s" $__NS__SIG_EMPTY
			if [[ $__NS__STATE == "$x_t" ]]; then
				"__NS__state_$x_s" $__NS__SIG_EXIT
				x_ip=0
			else
				if [[ $__NS__STATE == "${__NS__HSM_PATH[0]}" ]]; then
					"__NS__state_$x_s" $__NS__SIG_EXIT
				else
					x_iq=0
					x_ip=1
					__NS__HSM_PATH[1]=$x_t
					x_t=$__NS__STATE
					"__NS__state_${__NS__HSM_PATH[1]}" $__NS__SIG_EMPTY
					x_r=$?
					while (( x_r == __NS__RET_PARENT )); do
						(( ++x_ip ))
						__NS__HSM_PATH[x_ip]=$__NS__STATE
						if [[ $__NS__STATE == "$x_s" ]]; then
							x_iq=1
							# (( x_ip < MAX_NEST_DEPTH )) || assert
							(( --x_ip ))
							x_r=$__NS__RET_HANDLED
						else
							"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
							x_r=$?
						fi
					done
					if (( x_iq == 0 )); then
						# (( x_ip < MAX_NEST_DEPTH )) || assert
						"__NS__state_$x_s" $__NS__SIG_EXIT
						x_iq=$x_ip
						x_r=$__NS__RET_IGNORED
						while :; do
							if [[ $x_t == "${__NS__HSM_PATH[x_iq]}" ]]; then
								x_r=$__NS__RET_HANDLED
								((x_ip=x_iq-1 ))
								x_iq=-1
							else
								(( --x_iq ))
							fi
							(( x_iq >= 0 )) || break
						done
						if (( x_r != __NS__RET_HANDLED )); then
							x_r=$__NS__RET_IGNORED
							while :; do
								"__NS__state_$x_t" $__NS__SIG_EXIT
								if (( $? == __NS__RET_HANDLED )); then
									"__NS__state_$x_t" $__NS__SIG_EMPTY
								fi
								x_t=$__NS__STATE
								x_iq=$x_ip
								while :; do
									if [[ $x_t == "${__NS__HSM_PATH[x_iq]}" ]]; then
										(( x_ip=x_iq-1 ))
										x_iq=-1
										x_r=$__NS__RET_HANDLED
									else
										(( --x_iq ))
									fi
									(( x_iq >= 0 )) || break
								done
								(( x_r != __NS__RET_HANDLED )) || break
							done
						fi
					fi
				fi
			fi
		fi
	fi

	for (( ; x_ip >= 0; --x_ip )); do
		"__NS__state_${__NS__HSM_PATH[x_ip]}" $__NS__SIG_ENTRY
	done

	x_t=${__NS__HSM_PATH[0]}
	__NS__STATE=$x_t
	while :; do
		"__NS__state_$x_t" $__NS__SIG_INIT
		(( $? == __NS__RET_TRAN )) || break
		x_ip=0
		__NS__HSM_PATH[0]=$__NS__STATE
		"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
		while [[ $__NS__STATE != "$x_t" ]]; do
			(( ++x_ip ))
			__NS__HSM_PATH[x_ip]=$__NS__STATE
			"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
		done
		__NS__STATE=${__NS__HSM_PATH[0]}
		while :; do
			"__NS__state_${__NS__HSM_PATH[x_ip]}" $__NS__SIG_ENTRY
			(( --x_ip ))
			(( x_ip >= 0 )) || break
		done
		x_t=${__NS__HSM_PATH[0]}
	done

	__NS__STATE=$x_t
}


__NS__throw_state_machine_error() {
	exit 255
}

__NS__start_initial_state() {
	pragma local_prefix x_
	__NS__STATE=$1
	shift
	if [[ -z $2 ]]; then
		"__NS__state_$__NS__STATE" $__NS__SIG_INIT
	else
		"__NS__state_$__NS__STATE" "$@"
	fi
	if (( $? != __NS__RET_TRAN )); then
		__NS__throw_state_machine_error
	fi
	local x_t=TOP_STATE
	while :; do
		local -i x_ip=0
		__NS__HSM_PATH[0]=$__NS__STATE
		while :; do # create full path from childs to parents
			"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
			[[ $__NS__STATE == "$x_t" ]] && break
			(( ++x_ip ))
			__NS__HSM_PATH[x_ip]=$__NS__STATE
		done
		__NS__STATE=${__NS__HSM_PATH[0]}
		while :; do # execute entry actiions from parents to childs
			"__NS__state_${__NS__HSM_PATH[x_ip]}" $__NS__SIG_ENTRY
			(( --x_ip ))
			(( x_ip < 0 )) && break
		done
		x_t=${__NS__HSM_PATH[0]}
		"__NS__state_$x_t" $__NS__SIG_INIT
		(( $? != __NS__RET_TRAN )) && break
	done
	__NS__STATE=$x_t
}

__NS__instrument_state_machine() {
	local funcname=$1
	local code line
	local -i i=0
	if [[ -v $funcname ]]; then
		code=$(cat <<- EOF
			declare -g __NS__STATE
			declare -ga __NS__HSM_PATH=()
			EOF
		)
	else
		code=$(declare -pf "$funcname" |
			while read -r line; do
				printf '%s\n' "$line"
				if (( i==1 )); then
					cat <<- EOF
					local __NS__STATE
					local -a __NS__HSM_PATH=()
					EOF
					exec cat
				fi
				(( ++i ))
			done
		)
	fi
	eval "$code"
}
