#!/bin/bash



# export PS4='+ \e[1;37m${BASH_SOURCE}:${LINENO}${FUNCNAME[0]:+ @ ${FUNCNAME[0]}()}:\e[0m '
# set -x

upvar() {
	if unset -v "${1:?}"; then
		eval "$1"="${2?}"
	fi
}

upvar_array() {
	if unset -v "${1:?}"; then
		eval "$1=( \"\${@:2}\" )"
	fi
}


#shopt -s expand_aliases
## shellcheck disable=SC2142,SC2154
#alias retvar='local "${retvar:-return}" && upvar "${retvar:-return}" "$1" && return'
## shellcheck disable=SC2142,SC2154
#alias retarr='local "${retvar:-return}" && upvar_array "${retvar:-return}" "$@" && return'
## shellcheck disable=SC2142,SC2154
#alias rethash='local "${retvar:-return}" && upvar_hash "${retvar:-return}" "$@" && return'


get_short_id_length() {
	local alphabet_length=$1
	local result; result=$(bc -l <<- EOF
			define ceil(x) {
				auto os,xx;x=-x;os=scale;scale=0
				xx=x/1;if(xx>x).=xx--
				scale=os;return(-xx)
			}
			ceil( l(2 ^ 128) / l($alphabet_length) )
		EOF
	)
	local "${retvar:-return}" && upvar "${retvar:-return}" "$result"
}



base_conv_arr() {
	local val=$1
	local input_alphabet
	local output_alphabet
	local -i input_base=$2
	local -i output_base=$3

	local -a val_arr
	local -i i
	for ((i = 0; i < ${#val}; ++i)); do
		val_arr[i]=${val:$i:1}
	done

	local -i valCount=${#val_arr[@]}
	local -ai result=()
	while
		local -i divide=0
		local -i newlen=0
		local -i i
		for ((i = 0; i < valCount; ++i)); do
			divide=$(( divide * input_base + 0x${val_arr[i]} ))
			if (( divide >= output_base )); then
				val_arr[newlen++]=$(( divide / output_base ))
				divide=$((divide % output_base))
			elif (( newlen > 0 )); then
				val_arr[newlen++]=0
			fi
		done
		valCount=newlen
		result=( $divide ${result[@]} )
		(( newlen != 0 ))
	do :; done
	local "${retvar:-return}" && upvar_array "${retvar:-return}" "${result[@]}"
}


uuid_compress() {
	local uuid=$1
	local val=${uuid//-/}
	local output_alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' #62
	local -i output_base=${#output_alphabet}

	local -ai val_arr
	local -i i
	for (( i = 0; i < ${#val}; ++i )); do
		(( val_arr[i] = 0x${val:$i:1} ))
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
		compressed_uuid=${output_alphabet:$divide:1}${compressed_uuid}
		(( new_count != 0 ))
	do :; done
	local "${retvar:-return}" && upvar "${retvar:-return}" "$compressed_uuid"
}


declare uuid
read -r uuid < '/proc/sys/kernel/random/uuid'
declare -p uuid

declare result
retvar=result get_short_id_length 62
declare -p result

unset -v result
declare result
retvar=result uuid_compress "$uuid"
declare -p result


