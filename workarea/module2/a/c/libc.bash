
__generate_functions() {
	echo "generating function __NS__func_gen for libc" >&2

	__NS__func_gen() {
		local __ns__mylocal=1
		printf -- '%s\n' "func generated" >&2
	}
}
__generate_functions

__NS__func() {
	__NS__prova
	local __ns__mylocal=1
	printf -- '%s\n' "func" >&2
}

__NS__func1() {
	pragma require_functions __NS__func
	local __ns__mylocal1=1
	local __ns__mylocal2=1
	pragma local_prefix custom_
	local custom_mylocal1=1
	local custom_mylocal2=1
	printf -- '%s\n' "func" >&2
}

__NS__func_strip1() {
	pragma begin safe
	: safe
	pragma end
	local __ns__mylocal=1
	printf -- '%s\n' "func" >&2
}

__NS__func_strip2() {
	pragma begin dummy
		pragma begin safe
		: safe
		pragma end
		: dummy
	pragma end
	printf -- '%s\n' "func" >&2
}

__NS__func_strip3() {
	pragma begin safe
	: safe
	pragma end
	pragma begin debug
	: debug
	pragma end
	pragma local_prefix __IMPOSSIBLE__
	local __ns__mylocal='not replaced'
	printf -- '%s\n' "func" >&2
}
