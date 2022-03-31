bash_import ../b/libb.bash -p __NS__
bash_import ./c/libc.bash -p __NS__ func_gen


helper_fun() {
	local __ns__mylocal=1
	echo "helper fun in liba" >&2
}

__NS__funa() {
	pragma require_functions __NS__funa1 __NS__funa2
	local __ns__mylocal=1
	printf -- '%s\n' "funa"  >&2
}

__NS__funa1() {
	pragma require_functions __NS__funa2
	local __ns__mylocal=1
	printf -- '%s\n' "funa1"  >&2
}

__NS__funa2() {
	pragma require_functions __NS__funb
	local __ns__mylocal=1
	printf -- '%s\n' "funa2"  >&2
}



