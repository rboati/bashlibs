
source ../../bashlibs.bash
set_loglevel info

LIBA_funa() {
	printf -- '%s\n' "conflict funa"  >&2
}

bash_import ./a/liba.bash -p LIBA_
STRIP_PRAGMAS="safe debug" bash_import ./a/c/libc.bash -p LIBC_


# __NS__funa() {
# 	printf -- '%s\n' "funa";
# }

main() {
	#declare -pF

	#declare -f LIBC_func_strip1 LIBC_func_strip2 LIBC_func_strip3
	declare -pF $(compgen -A function LIB)

}

main
