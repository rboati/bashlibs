
declare -gri __NS__SIG_EMPTY=-4
declare -gri __NS__SIG_INIT=-3
declare -gri __NS__SIG_EXIT=-2
declare -gri __NS__SIG_ENTRY=-1

declare -gri __NS__RET_IGNORED=0
declare -gri __NS__RET_PARENT=1
declare -gri __NS__RET_HANDLED=2
declare -gri __NS__RET_TRAN=3

__NS__state_TOP_STATE() {
	return $__NS__RET_IGNORED
}


__NS__hsm_dispatch() {
	# In this function, names are messy on purpose to avoid user's names collisions
	local __NS____s__
	local __NS____t__=${__NS__STATE:?} # save current state
	local -i __NS____r__
	local -i __NS____ip__
	local -i __NS____iq__

	while :; do # send the event to the currente state, eventually descending into parents
		__NS____s__=$__NS__STATE
		"__NS__state_$__NS____s__" "${@}"
		__NS____r__=$?
		(( __NS____r__ != __NS__RET_PARENT )) && break
	done

	if (( __NS____r__ != __NS__RET_TRAN )); then
		__NS__STATE=$__NS____t__ # restore current state
		return
	fi

	# we have a transition
	# here __NS__STATE is the destination state of last transition, as requested by the user
	# here __NS____t__ is the original source state
	# here __NS____s__ is the source state of last transition

	__NS____ip__=-1
	__NS__HSM_PATH[0]=$__NS__STATE
	__NS__HSM_PATH[1]=$__NS____t__

	while [[ $__NS____t__ != "$__NS____s__" ]]; do
		"__NS__state_$__NS____t__" $__NS__SIG_EXIT
		if (( $? == __NS__RET_HANDLED )); then
			"__NS__state_$__NS____t__" $__NS__SIG_EMPTY
		fi
		__NS____t__=$__NS__STATE
	done
	__NS____t__=${__NS__HSM_PATH[0]}

	if [[ $__NS____s__ == "$__NS____t__" ]]; then
		"__NS__state_$__NS____s__" $__NS__SIG_EXIT
		__NS____ip__=0
	else
		"__NS__state_$__NS____t__" $__NS__SIG_EMPTY
		__NS____t__=$__NS__STATE;
		if [[ $__NS____s__ == "$__NS____t__" ]]; then
			__NS____ip__=0
		else
			"__NS__state_$__NS____s__" $__NS__SIG_EMPTY
			if [[ $__NS__STATE == "$__NS____t__" ]]; then
				"__NS__state_$__NS____s__" $__NS__SIG_EXIT
				__NS____ip__=0
			else
				if [[ $__NS__STATE == "${__NS__HSM_PATH[0]}" ]]; then
					"__NS__state_$__NS____s__" $__NS__SIG_EXIT
				else
					__NS____iq__=0
					__NS____ip__=1
					__NS__HSM_PATH[1]=$__NS____t__
					__NS____t__=$__NS__STATE
					"__NS__state_${__NS__HSM_PATH[1]}" $__NS__SIG_EMPTY
					__NS____r__=$?
					while (( __NS____r__ == __NS__RET_PARENT )); do
						(( ++__NS____ip__ ))
						__NS__HSM_PATH[__NS____ip__]=$__NS__STATE
						if [[ $__NS__STATE == "$__NS____s__" ]]; then
							__NS____iq__=1
							# (( __NS____ip__ < MAX_NEST_DEPTH )) || assert
							(( --__NS____ip__ ))
							__NS____r__=$__NS__RET_HANDLED
						else
							"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
							__NS____r__=$?
						fi
					done
					if (( __NS____iq__ == 0 )); then
						# (( __NS____ip__ < MAX_NEST_DEPTH )) || assert
						"__NS__state_$__NS____s__" $__NS__SIG_EXIT
						__NS____iq__=$__NS____ip__
						__NS____r__=$__NS__RET_IGNORED
						while :; do
							if [[ $__NS____t__ == "${__NS__HSM_PATH[__NS____iq__]}" ]]; then
								__NS____r__=$__NS__RET_HANDLED
								((__NS____ip__=__NS____iq__-1 ))
								__NS____iq__=-1
							else
								(( --__NS____iq__ ))
							fi
							(( __NS____iq__ >= 0 )) || break
						done
						if (( __NS____r__ != __NS__RET_HANDLED )); then
							__NS____r__=$__NS__RET_IGNORED
							while :; do
								"__NS__state_$__NS____t__" $__NS__SIG_EXIT
								if (( $? == __NS__RET_HANDLED )); then
									"__NS__state_$__NS____t__" $__NS__SIG_EMPTY
								fi
								__NS____t__=$__NS__STATE
								__NS____iq__=$__NS____ip__
								while :; do
									if [[ $__NS____t__ == "${__NS__HSM_PATH[__NS____iq__]}" ]]; then
										(( __NS____ip__=__NS____iq__-1 ))
										__NS____iq__=-1
										__NS____r__=$__NS__RET_HANDLED
									else
										(( --__NS____iq__ ))
									fi
									(( __NS____iq__ >= 0 )) || break
								done
								(( __NS____r__ != __NS__RET_HANDLED )) || break
							done
						fi
					fi
				fi
			fi
		fi
	fi

	for (( ; __NS____ip__ >= 0; --__NS____ip__ )); do
		"__NS__state_${__NS__HSM_PATH[__NS____ip__]}" $__NS__SIG_ENTRY
	done

	__NS____t__=${__NS__HSM_PATH[0]}
	__NS__STATE=$__NS____t__
	while :; do
		"__NS__state_$__NS____t__" $__NS__SIG_INIT
		(( $? == __NS__RET_TRAN )) || break
		__NS____ip__=0
		__NS__HSM_PATH[0]=$__NS__STATE
		"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
		while [[ $__NS__STATE != "$__NS____t__" ]]; do
			(( ++__NS____ip__ ))
			__NS__HSM_PATH[__NS____ip__]=$__NS__STATE
			"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
		done
		__NS__STATE=${__NS__HSM_PATH[0]}
		while :; do
			"__NS__state_${__NS__HSM_PATH[__NS____ip__]}" $__NS__SIG_ENTRY
			(( --__NS____ip__ ))
			(( __NS____ip__ >= 0 )) || break
		done
		__NS____t__=${__NS__HSM_PATH[0]}
	done

	__NS__STATE=$__NS____t__
}

__NS__hsm_throw_error() {
	exit 255
}

__NS__hsm_init() {
	__NS__STATE=$1
	shift
	if [[ -z $2 ]]; then
		"__NS__state_$__NS__STATE" $__NS__SIG_INIT
	else
		"__NS__state_$__NS__STATE" "$@"
	fi
	if (( $? != __NS__RET_TRAN )); then
		__NS__hsm_throw_error
	fi
	local __NS____t__=TOP_STATE
	while :; do
		local __NS____ip__=0
		__NS__HSM_PATH[0]=$__NS__STATE
		while :; do # create full path from childs to parents
			"__NS__state_$__NS__STATE" $__NS__SIG_EMPTY
			[[ $__NS__STATE == "$__NS____t__" ]] && break
			(( ++__NS____ip__ ))
			__NS__HSM_PATH[__NS____ip__]=$__NS__STATE
		done
		__NS__STATE=${__NS__HSM_PATH[0]}
		while :; do # execute entry actiions from parents to childs
			"__NS__state_${__NS__HSM_PATH[__NS____ip__]}" $__NS__SIG_ENTRY
			(( --__NS____ip__ ))
			(( __NS____ip__ < 0 )) && break
		done
		__NS____t__=${__NS__HSM_PATH[0]}
		"__NS__state_$__NS____t__" $__NS__SIG_INIT
		(( $? != __NS__RET_TRAN )) && break
	done
	__NS__STATE=$__NS____t__
}

__NS__hsm_instrument() {
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
