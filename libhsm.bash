
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
	local __NS____s__
	local __NS____t__=$__NS__STATE
	local -i __NS____r__
	local -i __NS____ip__
	local -i __NS____iq__

	while :; do
		__NS____s__=$__NS__STATE
		__NS__state_$__NS____s__ "${@}"
		__NS____r__=$?
		(( __NS____r__ == __NS__RET_PARENT )) || break
	done

	if (( __NS____r__ == __NS__RET_TRAN )); then
		__NS____ip__="-1"

		__NS__HSM_PATH[0]=$__NS__STATE
		__NS__HSM_PATH[1]=$__NS____t__

		while [[ $__NS____t__ != $__NS____s__ ]]; do
			__NS__state_$__NS____t__ $__NS__SIG_EXIT
			if (( $? == __NS__RET_HANDLED )); then
				__NS__state_$__NS____t__ $__NS__SIG_EMPTY
			fi
			__NS____t__=$__NS__STATE
		done
		__NS____t__=${__NS__HSM_PATH[0]}

		if [[ $__NS____s__ == $__NS____t__ ]]; then
			__NS__state_$__NS____s__ $__NS__SIG_EXIT
			__NS____ip__=0
		else
			__NS__state_$__NS____t__ $__NS__SIG_EMPTY
			__NS____t__=$__NS__STATE;
			if [[ $__NS____s__ == $__NS____t__ ]]; then
				__NS____ip__=0
			else
				__NS__state_$__NS____s__ $__NS__SIG_EMPTY
				if [[ $__NS__STATE == $__NS____t__ ]]; then
					__NS__state_$__NS____s__ $__NS__SIG_EXIT
					__NS____ip__=0
				else
					if [[ $__NS__STATE == ${__NS__HSM_PATH[0]} ]]; then
						__NS__state_$__NS____s__ $__NS__SIG_EXIT
					else
						__NS____iq__=0
						__NS____ip__=1
						__NS__HSM_PATH[1]=$__NS____t__
						__NS____t__=$__NS__STATE
						__NS__state_${__NS__HSM_PATH[1]} $__NS__SIG_EMPTY
						__NS____r__=$?
						while (( __NS____r__ == __NS__RET_PARENT )); do
							let ++__NS____ip__;
							__NS__HSM_PATH[$__NS____ip__]=$__NS__STATE
							if [[ $__NS__STATE == $__NS____s__ ]]; then
								__NS____iq__=1
								# assert __NS____ip__ < MAX_NEST_DEPTH;
								let --__NS____ip__
								__NS____r__=$__NS__RET_HANDLED
							else
								__NS__state_$__NS__STATE $__NS__SIG_EMPTY
								__NS____r__=$?
							fi
						done
						if (( __NS____iq__ == 0 )); then
							# assert __NS____ip__ < MAX_NEST_DEPTH;
							__NS__state_$__NS____s__ $__NS__SIG_EXIT
							__NS____iq__=$__NS____ip__
							__NS____r__=$__NS__RET_IGNORED
							while :; do
								if [[ $__NS____t__ == ${__NS__HSM_PATH[$__NS____iq__]} ]]; then
									__NS____r__=$__NS__RET_HANDLED
									let __NS____ip__=__NS____iq__-1
									__NS____iq__=-1
								else
									let --__NS____iq__
								fi
								(( __NS____iq__ >= 0 )) || break
							done
							if (( __NS____r__ != __NS__RET_HANDLED )); then
								__NS____r__=$__NS__RET_IGNORED
								while :; do
									__NS__state_$__NS____t__ $__NS__SIG_EXIT
									if (( $? == __NS__RET_HANDLED )); then
										__NS__state_$__NS____t__ $__NS__SIG_EMPTY
									fi
									__NS____t__=$__NS__STATE
									__NS____iq__=$__NS____ip__
									while :; do
										if [[ $__NS____t__ == ${__NS__HSM_PATH[$__NS____iq__]} ]]; then
											let __NS____ip__=__NS____iq__-1
											__NS____iq__=-1
											__NS____r__=$__NS__RET_HANDLED
										else
											let --__NS____iq__
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
			__NS__state_${__NS__HSM_PATH[$__NS____ip__]} $__NS__SIG_ENTRY
		done
		__NS____t__=${__NS__HSM_PATH[0]}
		__NS__STATE=$__NS____t__
		while :; do
			__NS__state_$__NS____t__ $__NS__SIG_INIT
			(( $? == __NS__RET_TRAN )) || break
			__NS____ip__=0
			__NS__HSM_PATH[0]=$__NS__STATE
			__NS__state_$__NS__STATE $__NS__SIG_EMPTY
			while [[ $__NS__STATE != $__NS____t__ ]]; do
				let ++__NS____ip__
				__NS__HSM_PATH[$__NS____ip__]=$__NS__STATE
				__NS__state_$__NS__STATE $__NS__SIG_EMPTY
			done
			__NS__STATE=${__NS__HSM_PATH[0]}
			# assert __NS____ip__ < MAX_NEST_DEPTH;
			while :; do
				__NS__state_${__NS__HSM_PATH[$__NS____ip__]} $__NS__SIG_ENTRY
				let --__NS____ip__
				(( __NS____ip__ >= 0 )) || break
			done
			__NS____t__=${__NS__HSM_PATH[0]}
		done
	fi
	__NS__STATE=$__NS____t__
}

__NS__hsm_throw_error() {
	exit -1
}

__NS__hsm_init() {
	local initialState="$1"
	shift
	__NS__STATE=$initialState
	if [[ -z $2 ]]; then
		__NS__state_$__NS__STATE $__NS__SIG_INIT
	else
		__NS__state_$__NS__STATE "$@"
	fi
	if (( $? != __NS__RET_TRAN )); then
		__NS__hsm_throw_error
	fi
	local t=TOP_STATE
	while :; do
		local __NS____ip__=0
		__NS__HSM_PATH[0]=$__NS__STATE
		__NS__state_$__NS__STATE $__NS__SIG_EMPTY
		while [[ $__NS__STATE != $t ]]; do
			let ++__NS____ip__
			__NS__HSM_PATH[$__NS____ip__]=$__NS__STATE
			__NS__state_$__NS__STATE $__NS__SIG_EMPTY
		done
		__NS__STATE=${__NS__HSM_PATH[0]}
		# assert __NS____ip__ < MAX_NEST_DEPTH;
		while :; do
			__NS__state_${__NS__HSM_PATH[$__NS____ip__]} $__NS__SIG_ENTRY
			let --__NS____ip__
			(( __NS____ip__ >= 0 )) || break
		done
		t=${__NS__HSM_PATH[0]}
		__NS__state_$t $__NS__SIG_INIT
		(( $? == __NS__RET_TRAN )) || break
	done
	__NS__STATE=$t
}

__NS__hsm_instrument() {
	local funcname="$1"
	local LINE
	local -i i=0
	if [[ -v $funcname ]]; then
		CODE="$(cat <<- EOF
			declare -g __NS__STATE
			declare -ga __NS__HSM_PATH=()
			EOF
		)"
	else
		CODE=$(declare -pf "$funcname" |
			while read -r LINE; do
				echo "$LINE"
				if (( i==1 )); then
					echo "local __NS__STATE"
					echo "local -a __NS__HSM_PATH=()"
					exec cat
				fi
				let ++i
			done
		)
	fi
	eval "$CODE"
}
