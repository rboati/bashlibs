LIB_VERSION=1

declare -p BASH_SOURCE
BASH_SOURCE[0]=./lib2.bash
declare -p BASH_SOURCE

EOF

__NS__hello() {
	#gdb --pid=$$
	caller 2
	echo "Hello"
	echo $(( 5/0 ))
}

