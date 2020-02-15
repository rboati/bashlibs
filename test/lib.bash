LIB_VERSION=1

__NS__hello() {
	echo "Hello"
}

__NS__generate_hello() {
	declare CODE
	CODE=$(cat <<- EOF
		__NS__hello2() {
			echo "Hello2"
		}
		EOF
	)
	eval "$CODE"
}


__NS__generate_hello

