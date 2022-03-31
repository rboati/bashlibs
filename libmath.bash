
__NS__base_conv() {
 	pragma local_prefix x_
	local x_val=$1
	local -n x_input_alphabet_map=${2}_map
	local -n x_output_alphabet_map=${3}_map
	local -n x_ret=${retvar:?}
	local -i x_input_base=${#x_input_alphabet_map[@]}
	local -i x_output_base=${#x_output_alphabet_map[@]}
	local -ai x_val_arr=()
	local -i x_i

	# local -a x_input_alphabet_arr=()
	# local -Ai x_input_alphabet_map=()
	# for (( x_i = 0; x_i < x_input_base; ++x_i )); do
	# 	local x_digit=${x_input_alphabet:x_i:1}
	# 	x_input_alphabet_arr[x_i]=$x_digit
	# 	x_input_alphabet_map[$x_digit]=x_i
	# done

	# local -a x_output_alphabet_arr=()
	# local -Ai x_output_alphabet_map=()
	# for (( x_i = 0; x_i < x_output_base; ++x_i )); do
	# 	local x_digit=${x_output_alphabet:x_i:1}
	# 	x_output_alphabet_arr[x_i]=$x_digit
	# 	x_output_alphabet_map[$x_digit]=x_i
	# done

	for (( x_i = 0; x_i < ${#x_val}; ++x_i )); do
		local x_digit=${x_val:$x_i:1}
		x_val_arr[x_i]=${x_input_alphabet_map[$x_digit]}
	done

	local -a x_result_arr=()
	retvar=x_result_arr __NS__base_conv_arr x_val_arr $x_input_base $x_output_base

	local x_result=''
	for (( x_i = 0; x_i < ${#x_result_arr[@]}; ++x_i )); do
		local x_digit=${x_result_arr[x_i]}
		x_result+=${x_output_alphabet_map[$x_digit]}
	done

	x_ret=$x_result
}


__NS__base_conv_arr() {
	pragma local_prefix x_
	local -n x_val_arr=$1
	local -i x_input_base=$2
	local -i x_output_base=$3
	local -n x_ret=${retvar:?}

	local -i x_val_count=${#x_val_arr[@]}
	local -ai x_result_arr=()
	while
		local -i x_divide=0
		local -i x_new_count=0
		for ((x_i = 0; x_i < x_val_count; ++x_i)); do
			(( x_divide = x_divide * x_input_base + x_val_arr[x_i] ))
			if (( x_divide >= x_output_base )); then
				(( x_val_arr[x_new_count++] = x_divide / x_output_base ))
				(( x_divide = x_divide % x_output_base ))
			elif (( x_new_count > 0 )); then
				(( x_val_arr[x_new_count++] = 0 ))
			fi
		done
		(( x_val_count = x_new_count ))
		# shellcheck disable=SC2206
		x_result_arr=( $x_divide ${x_result_arr[@]} )
		(( x_new_count != 0 ))
	do :; done
	xret=( "${x_result_arr[@]}" )
}

__NS__make_base_alphabet() {
	pragma local_prefix x_
	local x_name=$1
	shift
	local -n x_arr=${x_name}_arr
	local -n x_map=${x_name}_map
	x_arr=()
	x_map=()
	for (( x_i = 1; x_i < ($# + 1); ++x_i )); do
		local x_digit=${!x_i}
		x_arr[$((x_i - 1))]=$x_digit
		x_map[$x_digit]=$(( x_i -1 ))
	done
}