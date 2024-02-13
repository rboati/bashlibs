#!/bin/bash

uuid_compress() {
	local uuid=$1
	local val=${uuid//-/}
	local output_alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' #62
	local -i output_base=${#output_alphabet}
	compressed_uuid=$(base_convert "$val" 16 $output_base)
	printf '%s' "$compressed_uuid"
}

uuid_expand() {
	local compressed_uuid=$1
	local input_alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' #62
	local -i input_base=${#input_alphabet}
	local expanded_uuid
	expanded_uuid=$(base_convert "$compressed_uuid" $input_base 16)
	printf -v expanded_uuid '%32s' "$expanded_uuid"
	expanded_uuid=${expanded_uuid// /0}
	printf '%8s-%4s-%4s-%4s-%12s' "${expanded_uuid:0:8}" "${expanded_uuid:8:4}" "${expanded_uuid:12:4}" "${expanded_uuid:16:4}" "${expanded_uuid:20:12}"
}

base_convert() {
	local val=$1
	local -i input_base=${2:-10}
	local -i output_base=${3:-16}
	local input_alphabet=${4:-'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'}
	local output_alphabet=${5:-'0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'}
	local -A input_alphabet_map
	local -i i
	for (( i = 0; i < input_base; ++i )); do
		input_alphabet_map[${input_alphabet:i:1}]=$i
	done

	local -ai val_arr
	for (( i = 0; i < ${#val}; ++i )); do
		val_arr[i]=${input_alphabet_map[${val:i:1}]}
	done

	local -i val_count=${#val_arr[@]}
	local output_val=''
	while # "do while" in a bash pattern
		local -i divide=0
		local -i new_count=0
		local -i i
		for (( i = 0; i < val_count; ++i )); do
			(( divide = divide * input_base + val_arr[i] ))
			if (( divide >= output_base )); then
				(( val_arr[new_count++] = divide / output_base ))
				(( divide = divide % output_base ))
			elif (( new_count > 0 )); then
				(( val_arr[new_count++] = 0 ))
			fi
		done
		(( val_count = new_count ))
		output_val=${output_alphabet:divide:1}${output_val}
		(( new_count != 0 ))
	do :; done
	printf '%s' "$output_val"
}

@trace_function() {
	local name=${1?missing function name}
	local uuid
	IFS= read -r -d '' uuid < '/proc/sys/kernel/random/uuid'
	uuid=$(uuid_compress "$uuid")
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


@local_prefix() {
	local name=${1?missing function name}
	local local_prefix=$2
	local -i trunc=$3
	local uuid
	IFS= read -r -d '' uuid < '/proc/sys/kernel/random/uuid'
	uuid=$(uuid_compress "$uuid")
	if (( trunc > 0 && trunc < 23 )); then
		uuid=${uuid:0:trunc}
	fi
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
			printf 'WARN: pragma %s not found\n' "${pragma%% *}" >&2
		fi
	done

	declare -fp "$name"
	declare -p pragmas
}


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


@pragma() { return $?; }
@region() { return $?; }
@endregion() { return $?; }

@pragma_aaa() {
	for i in "$@"; do
		echo "aaa: '$i'"
	done
}

@pragma_local_prefix() {
	local name=${1?missing function name}
	local local_prefix=$2
	local -i trunc=$3
	local uuid
	IFS= read -r -d '' uuid < '/proc/sys/kernel/random/uuid'
	uuid=$(uuid_compress "$uuid")
	if (( trunc > 0 && trunc < 23 )); then
		uuid=${uuid:0:trunc}
	fi
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



__libimport_filter_function_code() {
	local ns=$1
	local line token
	local IFS=$' \t\n'
	local global_prefix='__N''S__'
	local local_prefix=''
	local uuid=''
	local pragma_re='^\s*pragma\s+(\w+)\s*(.*);$'
	local prefix_re1='^(.*\b)' prefix_re2='(\w+.*)$'
	local pragma_begin_re='^\s*pragma\s+begin\s+([_[:alnum:]]+)\s*(.*);$'
	local pragma_end_re='^\s*pragma\s+end\s*(.*);$'
	local -a token_list
	local -Ai strip_pragma_set=()
	local pragma
	if [[ -n $STRIP_PRAGMA ]]; then
		# shellcheck disable=SC2086
		local -a strip_pragma_list=()
		IFS=$' \t\n,:' read -r -d '' -a strip_pragma_list <<< "$STRIP_PRAGMA"
		for pragma in "${strip_pragma_list[@]}"; do
			strip_pragma_set[$pragma]=1
		done
		#region Expand directives
		while (( ${#strip_pragma_list[@]} > 0 )); do
			pragma=${strip_pragma_list[0]} && strip_pragma_list=( "${strip_pragma_list[@]:1}" ) # pop from head
			if [[ $pragma == 'loglevel='* ]]; then
				local loglevel=${pragma#loglevel=}
				loglevel=${loglevel,,}
				case $loglevel in
					off|0)   ;&
					fatal|1) strip_pragma_set['loglevel=error']=1; strip_pragma_set['loglevel=2']=1 ;&
					error|2) strip_pragma_set['loglevel=warn']=1 ; strip_pragma_set['loglevel=3']=1 ;&
					warn|3)  strip_pragma_set['loglevel=info']=1 ; strip_pragma_set['loglevel=4']=1 ;&
					info|4)  strip_pragma_set['loglevel=debug']=1; strip_pragma_set['loglevel=5']=1 ;&
					debug|5) strip_pragma_set['loglevel=trace']=1; strip_pragma_set['loglevel=6']=1 ;&
					trace|6) ;;
				esac
			fi
		done
		#endregion Expand directives
	fi
	local body=''
	local -i state=0
	while read -r line; do
		case $state in
		0) # no stripping
			if [[ $line =~ $pragma_begin_re ]]; then
				pragma=${BASH_REMATCH[1]}
				if [[ ${strip_pragma_set[$pragma]} == 1 ]]; then
					(( ++level ))
					state=1 && continue
				fi
			elif [[ $line =~ $pragma_re ]]; then
				read -r -d '' -a token_list <<<"${BASH_REMATCH[2]}"
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
					logdomain)
						local module=${__libimport_module_path##*/}
						module=${module%.*}
						local funcname=${__libimport_item/#$global_prefix/$ns}
						body+="local LOGDOMAIN=\"${funcname}\""$'\n'
						continue
						;;

				esac
				continue
			fi
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
			if [[ $global_prefix != "$ns" ]]; then
				local undone_part=$line done_part=''
				# Avoiding infinite loop by looking for a match only in the previously unmatched part
				# Because of the greedy operator *, the unmatched part is on the left (match group 2)
				while [[ $undone_part =~ ${prefix_re1}"$global_prefix"${prefix_re2} ]]; do
					undone_part=${BASH_REMATCH[1]}
					done_part=${ns}${BASH_REMATCH[2]}${done_part}
					line=${undone_part}${done_part}
				done
			fi
			#endregion Replace namespace prefixes

			body+=${line}$'\n'
			;;
		1) # stripping
			if [[ $line =~ $pragma_begin_re ]]; then
				(( ++level ))
			elif [[ $line =~ $pragma_end_re ]]; then
				(( --level ))
				if (( level == 0 )); then
					state=0 && continue
				fi
				if (( level < 0 )); then
					return 1
				fi
			fi
			;;
		esac
	done

	printdebug 'Function body before returning: %s' "$body"
	local "$retvar" && retvar "$body"
}

join() {
	: "${1?Missing separator}" "${2?Missing input array var}" "${3?Missing output var}"
	local IFS=$1
	eval "$3=\${$2[*]}"
}

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
@local_prefix myfun_decorator x_ 8
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


declare o_uuid s_uuid e_uuid
IFS= read -r o_uuid < '/proc/sys/kernel/random/uuid'

s_uuid=$(uuid_compress "$o_uuid")
e_uuid=$(uuid_expand "$s_uuid")

declare -p o_uuid s_uuid e_uuid

declare in out out2
in='1232dd45343abacddfe'
out=$(base_convert '1232dd45343abacddfe' 16 10)
out2=$(base_convert $out 10 16)
declare -p in out out2


join / a