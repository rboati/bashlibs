bash_import ../b/libb.bash -p __NS__
bash_import ./c/libc.bash -p __NS__


__init__() {
	echo "init liba" >&2
}

__NS__funa() {
	.require_functions __NS__funa1 __NS__funa2
	printf -- '%s\n' "funa"  >&2
}

__NS__funa1() {
	.require_functions __NS__funa2
	printf -- '%s\n' "funa1"  >&2
}

__NS__funa2() {
	.require_functions __NS__funb
	printf -- '%s\n' "funa2"  >&2
}



