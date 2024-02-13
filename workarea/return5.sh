#!/bin/bash

chr () {
	printf -v "$2" '%x' "$1"
	# shellcheck disable=SC2059
	printf -v "$2" '\U'"${!2}"
}

ord() {
	LC_CTYPE=C.UTF-8 printf -v "$2" '%d' "'$1"
}

join() {
	: "${1?Missing separator}" "${2?Missing input array var}" "${3?Missing output var}"
	local IFS=$1
	eval "$3=\${$2[*]}"
}

# uuid_compress() {
# 	local uuid=$1
# 	local val=${uuid//-/}
# 	local output_alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' #62
# 	local -i output_base=${#output_alphabet}
# 	compressed_uuid=$(base_convert "$val" 16 $output_base)
# 	printf '%s' "$compressed_uuid"
# }

# uuid_expand() {
# 	local compressed_uuid=$1
# 	local input_alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' #62
# 	local -i input_base=${#input_alphabet}
# 	local expanded_uuid
# 	expanded_uuid=$(base_convert "$compressed_uuid" $input_base 16)
# 	printf -v expanded_uuid '%32s' "$expanded_uuid"
# 	expanded_uuid=${expanded_uuid// /0}
# 	printf '%8s-%4s-%4s-%4s-%12s' "${expanded_uuid:0:8}" "${expanded_uuid:8:4}" "${expanded_uuid:12:4}" "${expanded_uuid:16:4}" "${expanded_uuid:20:12}"
# }

# base_convert() {
# 	local val=$1
# 	local -i input_base=${2:-10}
# 	local -i output_base=${3:-16}
# 	local input_alphabet=${4:-'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'}
# 	local output_alphabet=${5:-'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'}
# 	local -A input_alphabet_map
# 	local -i i
# 	for (( i = 0; i < input_base; ++i )); do
# 		input_alphabet_map[${input_alphabet:i:1}]=$i
# 	done

# 	local -ai val_arr
# 	for (( i = 0; i < ${#val}; ++i )); do
# 		val_arr[i]=${input_alphabet_map[${val:i:1}]}
# 	done

# 	local -i val_count=${#val_arr[@]}
# 	local output_val=''
# 	while # "do while" in a bash pattern
# 		local -i divide=0
# 		local -i new_count=0
# 		local -i i
# 		for (( i = 0; i < val_count; ++i )); do
# 			(( divide = divide * input_base + val_arr[i] ))
# 			if (( divide >= output_base )); then
# 				(( val_arr[new_count++] = divide / output_base ))
# 				(( divide = divide % output_base ))
# 			elif (( new_count > 0 )); then
# 				(( val_arr[new_count++] = 0 ))
# 			fi
# 		done
# 		(( val_count = new_count ))
# 		output_val=${output_alphabet:divide:1}${output_val}
# 		(( new_count != 0 ))
# 	do :; done
# 	printf '%s' "$output_val"
# }

# @local_prefix() {
# 	local name=${1?missing function name}
# 	local local_prefix=$2
# 	local -i trunc=$3
# 	local uuid
# 	IFS= read -r -d '' uuid < '/proc/sys/kernel/random/uuid'
# 	uuid=$(uuid_compress "$uuid")
# 	if (( trunc > 0 && trunc < 23 )); then
# 		uuid=${uuid:0:trunc}
# 	fi
# 	local body
# 	local left_re='^(.*)\b' right_re='(\w+.*)$'

# 	body=$(declare -f "$name" | {
# 		local line
# 		# shellcheck disable=SC2030
# 		while read -r line; do
# 			local pending_part=$line done_part=''
# 			while [[ $pending_part =~ ${left_re}"$local_prefix"${right_re} ]]; do
# 				pending_part=${BASH_REMATCH[1]}
# 				done_part=_${uuid}_${BASH_REMATCH[2]}${done_part}
# 				line=${pending_part}${done_part}
# 			done
# 			printf '%s\n' "$line"
# 		done
# 	})
# 	eval "$body"
# }

@pragma() { return $?; }
@region() { return $?; }
@endregion() { return $?; }

make_alphabet() {
	@pragma local_prefix x_
	local -n x_arr=$1
	[[ ${x_arr@a} == *A* ]] || return 1 # TODO
	local -i x_i x_len=${#2} x_digit=0
	local x_char
	for (( x_i = 0; x_i < x_len; ++x_i )); do
		x_char=${2:x_i:1}
		[[ -v x_arr[$x_char] ]] && continue
		(( x_arr[$x_char] = x_digit++ ))
		x_arr['alphabet']+=$x_char
	done
	declare -p x_arr
}

base_convert2() {
	@pragma local_prefix my_
	local my_input_val=$1
	local -i my_input_base=$2
	local -n my_input_alphabet=$3
	local -i my_output_base=$4
	local -n my_output_alphabet=$5
	local -n my_ret=$6

	local -ai my_val_arr
	local -i my_i
	for (( my_i = 0; my_i < ${#my_input_val}; ++my_i )); do
		(( my_val_arr[my_i] = my_input_alphabet[${my_input_val:my_i:1}] ))
	done

	local my_output_val
	local -i my_val_count=${#my_val_arr[@]}
	while # "do while" in a bash pattern
		local -i my_divide=0
		local -i my_new_count=0
		for (( my_i = 0; my_i < my_val_count; ++my_i )); do
			(( my_divide = my_divide * my_input_base + my_val_arr[my_i] ))
			if (( my_divide >= my_output_base )); then
				(( my_val_arr[my_new_count++] = my_divide / my_output_base ))
				(( my_divide = my_divide % my_output_base ))
			elif (( my_new_count > 0 )); then
				(( my_val_arr[my_new_count++] = 0 ))
			fi
		done
		(( my_val_count = my_new_count ))
		my_output_val=${my_output_alphabet[alphabet]:my_divide:1}${my_output_val}
		(( my_new_count != 0 ))
	do :; done
	#shellcheck disable=SC2034
	my_ret=$my_output_val
}

# shellcheck disable=SC2034
declare -A alphabet_62
make_alphabet alphabet_62 '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'


get_unique_id() {
	@pragma local_prefix x_
	local -n x_ret=$1
	local x_uuid
	IFS= read -r -d '' x_uuid < '/proc/sys/kernel/random/uuid'
	local x_val=${x_uuid//-/}
	base_convert2 "$x_val" 16 alphabet_62 62 alphabet_62 x_val
	# shellcheck disable=SC2034
	x_ret=${x_val:0:8}
}


@pragma_local_prefix() {
	local name=${1?missing function name}
	local local_prefix=$2
	[[ $local_prefix =~ ^[[:alnum:]_]+$ ]] || return 1
	local uuid
	get_unique_id uuid
	local body
	local left_re='^(.*)\b' right_re='(\w+.*)$'

	body=$(declare -f "$name" | {
		local line
		# shellcheck disable=SC2030
		while read -r line; do
			local pending_part=$line done_part=''
			while [[ $pending_part =~ ${left_re}"$local_prefix"${right_re} ]]; do
				pending_part=${BASH_REMATCH[1]}
				done_part=_${uuid}_${BASH_REMATCH[2]}${done_part}
				line=${pending_part}${done_part}
			done
			printf '%s\n' "$line"
		done
	})
	eval "$body"
}


@trace_function() {
	local name=${1?missing function name}
	local uuid
	IFS= read -r -d '' uuid < '/proc/sys/kernel/random/uuid'
	get_unique_id uuid
	local body
	body=$(declare -f "$name" | {
		local line
		read -r line
		printf '_%s_%s ()\n' "$uuid" "$name"
		while read -r line; do
			printf '%s\n' "$line"
		done
		cat <<-EOF

		$name () {
			local -i _${uuid}_exit_code=\$?;
			printf 'TRACE:Entering %s\n' "$name";
			set -x;
			_${uuid}_${name} "\$@";
			set +x;
			printf 'TRACE:Exiting %s: %d\n' "$name" \$_${uuid}_exit_code;
			return \$_${uuid}_exit_code
		}
		EOF
	})
	eval "$body"
}




apply_pragmas() {
	local -r name=${1?missing function name}
	local -r pragma_re='^\s*@pragma\s+(\w+)\s*(.*);$'
	local line body
	local -a pragmas=()
	{
		read -r line # function_name ()
		body+="$line"$'\n'
		read -r line # {
		body+="$line"$'\n'
		while read -r line; do
			if [[ $line =~ $pragma_re ]]; then
				pragmas+=( "${BASH_REMATCH[*]:1:1}"\ "${name@Q}"\ "${BASH_REMATCH[*]:2}" ) 
				continue
			fi
			body+="$line"$'\n'
			while read -r line; do
				body+="$line"$'\n'
			done
			break
		done
	} < <(declare -fp "$name")
	(( ${#pragmas[@]} == 0 )) && return
	eval "$body"
	unset line body

	local pragma
	for pragma in "${pragmas[@]}"; do
		if declare -fp "@pragma_${pragma%% *}" &> /dev/null; then
			eval "@pragma_$pragma"
		else
			printf 'WARN: pragma %s not found in %s\n' "${pragma%% *}" "$name" >&2
		fi
	done
}

apply_pragmas get_unique_id
apply_pragmas make_alphabet
apply_pragmas base_convert2


apply_regions() {
	local -r name=${1?missing function name}
	local -r region_begin_re='^\s*@region\s+([_[:alnum:]]+)\s*(.*);$'
	local -r region_end_re='^\s*@endregion\s*.*;$'
	local line 
	local -a region_label=( '' )
	local -a region_body=()
	local -i level=0
	{
		read -r line # function_name ()
		region_body[level]+="$line"$'\n'
		read -r line # {
		region_body[level]+="$line"$'\n'
		while read -r line; do
			if [[ $line =~ $region_begin_re ]]; then
				region_label+=( "${BASH_REMATCH[*]:1}" )
				(( ++level ))
			elif [[ $line =~ $region_end_re ]]; then
				if (( level == 0 )); then
					printf 'WARN: ignoring unmatched end region\n' >&2 # TODO
					continue
				fi
				declare -pF "@region_${region_label[level]}" &> /dev/null && {
					eval "@region_${region_label[level]}"
				}
				region_body[level-1]+=${region_body[level]}
				unset 'region_body[level]' 'region_label[level]'
				(( --level ))
			else
				region_body[level]+="$line"$'\n'
			fi
		done
	} < <(declare -fp "$name")
	(( ${#region_label[@]} == 0 )) && return
	eval "${region_body[0]}"
}

@region_1() {
	local -n body='region_body[level]'
	printf 'region 1: %s\n' "${region_body[level]@Q}"
}



@pragma_aaa() {
	for i in "$@"; do
		echo "aaa: '$i'"
	done
}

# @pragma_local_prefix() {
# 	local name=${1?missing function name}
# 	local local_prefix=$2
# 	local -i trunc=$3
# 	local uuid
# 	IFS= read -r -d '' uuid < '/proc/sys/kernel/random/uuid'
# 	uuid=$(uuid_compress "$uuid")
# 	if (( trunc > 0 && trunc < 23 )); then
# 		uuid=${uuid:0:trunc}
# 	fi
# 	local body
# 	local left_re='^(.*)\b' right_re='(\w+.*)$'

# 	body=$(declare -f "$name" | {
# 		local line
# 		# shellcheck disable=SC2030
# 		while read -r line; do
# 			local pending_part=$line done_part=''
# 			while [[ $pending_part =~ ${left_re}"$local_prefix"${right_re} ]]; do
# 				pending_part=${BASH_REMATCH[1]}
# 				done_part=_${uuid}_${BASH_REMATCH[2]}${done_part}
# 				line=${pending_part}${done_part}
# 			done
# 			printf '%s\n' "$line"
# 		done
# 	})
# 	eval "$body"
# }





myfun() {
	local local_var=" \" ;? aa"
	printf 'EXPECTED: %s\n' "$(declare -p local_var)"
	local $retvar && retvar "$local_var"
}

myfun_array() {
	local -a local_array=(1 2 3 ');' 'ls' )
	printf 'EXPECTED: %s\n' "$(declare -p local_array)"
	local $retvar && retvar2 "${local_array[@]}"
}

myfun_assoc() {
	local -A local_assoc=([a a]="1 1" [b );ls]="  2 2  "  [c c]='3");ls')
	printf 'EXPECTED: %s\n' "$(declare -p local_assoc)"
	local $retvar && retvar_assoc "${local_assoc[@]@k}"
}

myfun_multi() {
	local la="hello"
	local -a lb=(1 2 3)
	local -A lc=(a '1;1' b');' 2');' c 3)
	printf 'EXPECTED: %s\n' "$(declare -p la lb lc)"
	local $1 $2 $3 && retvars -v $1 "$la" -a ${#lb[@]} $2 "${lb[@]}" -A ${#lc[@]} $3 "${lc[@]@k}"
}

myfun_decorator() {
	local -n x_a=$1 x_b=$2 x_c=$3
	local x_la="hello"
	local -a x_lb=(1 2 3)
	local -A x_lc=(a '1;1' b');' 2');' c 3)
	printf 'EXPECTED: %s\n' "$(declare -p x_la x_lb x_lc)"
	x_a=$x_la
	x_b=( "${x_lb[@]}" )
	local x_key
	for x_key in "${!x_lc[@]}"; do
		x_c[$x_key]=${x_lc[$x_key]}
	done
}
@pragma_local_prefix myfun_decorator x_
@trace_function myfun_decorator

myfun_pragma() {
	@pragma aaa 1 "A A"  2 3
	@pragma bbb 1 2
	@pragma local_prefix x_ 8
	local -n x_a=$1 x_b=$2 x_c=$3
	@region 1
	local x_la="hello"
	@pragma bbb
	local -a x_lb=(1 2 3)
	local -A x_lc=(a '1;1' b');' 2');' c 3)
	@region 2
	printf 'EXPECTED: %s\n' "$(declare -p x_la x_lb x_lc)"
	x_a=$x_la
	@endregion

	x_b=( "${x_lb[@]}" )
	@endregion
	local x_key
	for x_key in "${!x_lc[@]}"; do
		x_c[$x_key]=${x_lc[$x_key]}
	done
}
apply_pragmas myfun_pragma
apply_regions myfun_pragma
declare -fp myfun_pragma


false && {
	declare var
	retvar=var myfun
	printf 'GOT: %s\n' "$(declare -p var)"
	printf -- '-----------\n'
}

false && {
	declare -a array
	retvar=array myfun_array
	printf 'GOT: %s\n' "$(declare -p array)"
	printf -- '-----------\n'
}

false && {
	declare -A assoc
	retvar=assoc myfun_assoc
	printf 'GOT: %s\n' "$(declare -p assoc)"
	printf -- '-----------\n'
}

false && {
	declare a
	declare -a b
	declare -A c
	myfun_multi a b c
	printf 'GOT: %s\n' "$(declare -p a b c)"
	printf -- '-----------\n'
}

true && {
	declare a
	declare -a b
	declare -A c
	myfun_decorator a b c
	printf 'GOT: %s\n' "$(declare -p a b c)"
	printf -- '-----------\n'

}


# declare o_uuid s_uuid e_uuid
# IFS= read -r o_uuid < '/proc/sys/kernel/random/uuid'
# s_uuid=$(uuid_compress "$o_uuid")
# e_uuid=$(uuid_expand "$s_uuid")
# declare -p o_uuid s_uuid e_uuid

# declare in out out2
# in='1232dd45343abacddfe'
# out=$(base_convert '1232dd45343abacddfe' 16 10)
# out2=$(base_convert $out 10 16)
# declare -p in out out2


declare uuid
get_unique_id uuid
declare -p uuid

declare val
base_convert2 "f" 16 alphabet_62 62 alphabet_62 val
declare -p val
