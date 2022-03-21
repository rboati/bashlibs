#!/bin/bash

declare -i TIMES=10
declare -i i

#region Main functions
main0() {
	local output
	output=$(myfun 1 2)
	#echo "$output"
}

main1() {
	local myfun_output
	myfun 1 2
	#echo "$myfun_output"
}

main2() {
	local myfun_output
	myfun myfun_output 1 2
	#echo "$myfun_output"
}

main3() {
	local myfun_output
	myfun myfun_ 1 2
	#echo "$myfun_output"
}

main3() {
	local myfun_output
	myfun myfun_ 1 2
	#echo "$myfun_output"
}

main4() {
	local output
	local -n return
	return=output myfun 1 2
	echo "$output"
}

#endregion

#region Standard output
false && {
echo -n "Standard output"

myfun() {
	local a=$1 b=$2
	local c=$(( a + b ))
	printf '%s\n' "$c"
}

time for ((i=0; i < TIMES; ++i )); do
	main0 > /dev/null
done
}
#endregion

#region Var based on function name
echo -n "Var based on function name"

myfun() {
	local a=$1 b=$2
	local c=$(( a + b))
	myfun_output=$c
}

time for ((i=0; i < TIMES; ++i )); do
	main1 > /dev/null
done
#endregion

#region Var based on function name (less repetition)
echo -n "Var based on function name (less repetition)"

myfun() {
	local a=$1 b=$2
	local c=$(( a + b))
	eval ${FUNCNAME}_output=${c@Q}
}

time for ((i=0; i < TIMES; ++i )); do
	main1 > /dev/null
done
#endregion

#region Nameref and additional positional argument for name (DANGEROUS)
echo -n "Nameref and additional positional argument for name (DANGEROUS)"

myfun() {
	local -n out=$1 # possible collision !!!
	local a=$2 b=$3
	local c=$(( a + b))
	out=$c
}

time for ((i=0; i < TIMES; ++i )); do
	main2 > /dev/null
done
#endregion

#region Nameref and additional positional argument for prefix
echo -n "Nameref and additional positional argument for prefix"

myfun() {
	local -n out=${1}output
	local a=$2 b=$3
	local c=$(( a + b))
	out=$c
}

time for ((i=0; i < TIMES; ++i )); do
	main3 > /dev/null
done
#endregion

#region Eval and additional positional argument for name
echo -n "Eval and additional positional argument for name"

myfun() {
	local out_name=$1
	local a=$2 b=$3
	local c=$(( a + b))
	eval $out_name=${c@Q}
}

time for ((i=0; i < TIMES; ++i )); do
	main2 > /dev/null
done
#endregion

#region Eval and additional positional argument for prefix
echo -n "Eval and additional positional argument for prefix"

myfun() {
	local prefix=$1
	local a=$2 b=$3
	local c=$(( a + b))
	eval ${prefix}output=${c@Q}
}

time for ((i=0; i < TIMES; ++i )); do
	main3 > /dev/null
done
#endregion

#region Generic name for any return, using a nameref fixes types (-i -a -A) problems
echo -n "Generic name for any return, using a nameref fixes types (-i -a -A) problems"

myfun() {
	local a=$1 b=$1
	local c=$(( a + b))
	ret=$c
}

time for ((i=0; i < TIMES; ++i )); do
	main4 > /dev/null
done
#endregion



# Results for 1000000 iterations
#
# Var based on function name
# real    0m35,545s
# user    0m27,851s
# sys     0m7,545s
#
# Var based on function name (less repetition)
# real    0m44,945s
# user    0m35,664s
# sys     0m9,123s
#
# Nameref and additional positional argument for name (DANGEROUS)
# real    0m39,728s
# user    0m31,660s
# sys     0m7,913s
#
# Nameref and additional positional argument for prefix
# real    0m40,829s
# user    0m32,653s
# sys     0m8,022s
#
# Eval and additional positional argument for name
# real    0m48,525s
# user    0m39,072s
# sys     0m9,294s
#
# Eval and additional positional argument for prefix
# real    0m48,627s
# user    0m39,301s
# sys     0m9,166s

upvar() {
	if unset -v "$1"; then
		if (( $# == 2 )); then
			eval $1=\$2
		else
			eval $1=\(\"\${@:2}\"\)
		fi
	fi
}

die() {
	printf '%s\n' "${1:-}"
	# shellcheck disable=SC2086
	exit ${2:-1}
}


_upvar() {
	if unset -v "$1"; then
		if (( $# == 2 )); then
			eval $1=\$2
		else
			eval $1=\(\"\${@:2}\"\)
		fi
	fi
}


upvar() {
	#[[ $___v___ == ___v___ ]] && die 'Name ___v___ is reserved, cannot be used'
	local -n ___v___=$1
	if unset -v "$1"; then
		if (( $# == 2 )); then
			___v___=$2
		else
			___v___=( "${@:2}" )
		fi
	fi
}


myfun() {
	local a=$1 b=$2
	local c=$(( a + b ))
	local -A d=( ['a']=1 ['b']=2 )
	local retvar=${retvar:=return} && upvar "$retvar" "$c"
}

myfun() {
	local a=$1 b=$2
	local c=$(( a + b ))
	local -A d=( ['a']=1 ['b']=2 )
	local retvar=${retvar:=return}
	set -- "$retvar" "$c" && unset -v "$1" && eval $1=\$2
}



time for ((i=0; i<10000; ++i)); do
	myfun 1 2
done
exit

echo -----------
myfun 1 2 ; declare -p return
unset -v return

echo -----------
declare res
retvar=res myfun 1 2 ; declare -p res
unset -v return res myfun

echo -----------
declare d
declare -n return=d
myfun 1 2 ; declare -p return d
unset -v return d

echo -----------
declare -n d=res
retvar=d myfun 1 2 ; declare -p return d res
unset -v return d res

echo done

