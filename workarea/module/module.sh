# shellcheck shell=bash


__init__() {
	declare -g MYGLOBAL
}

__fini__() {
	unset -v MYGLOBAL
}



myfun1() {
	.require_functions myfun2 __NS1__myfun3
	.require_commands sed cat my\ cmd
	myfun2 "$@"
}


myfun2() {
	printf -- '%s\n' 'myfun2' "$@"
}

myfun3() {
	printf -- '%s\n' 'myfun3' "$@"
}


# import_map() {
# 	local -A generated_functions
# 	while (( $# > 0 )); do
# 		if [[ $1 == myfun1 && ! -v generated_functions[$1] ]]; then
# 			myfun1() {
# 				myfun2 "$@"
# 			}

# 			set -- "$@"

# 			generated_functions[$1]=1
# 		fi
# 	done
# }

