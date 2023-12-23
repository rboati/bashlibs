
source ../../bashlibs.bash
#set_loglevel trace

LIBA_funa() {
	printf -- '%s\n' "conflict funa"  >&2
}

bash_import ./a/liba.bash -p LIBA_
STRIP_PRAGMA="safe debug" bash_import ./a/c/libc.bash -p LIBC_


# __NS__funa() {
# 	printf -- '%s\n' "funa";
# }

main() {
	#declare -pF

	#declare -f LIBC_func_strip1 LIBC_func_strip2 LIBC_func_strip3
	declare -pF $(compgen -A function LIB)
	declare -f $(compgen -A function LIBC)

}

main
