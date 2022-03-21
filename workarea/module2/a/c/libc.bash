
__init__() {
	echo "init libc" >&2

	__NS__func_gen() {
		printf -- '%s\n' "func generated" >&2
	}
}

__NS__func() {
	printf -- '%s\n' "func" >&2
}
