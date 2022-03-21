

bash_import ./libb.bash=__NS__b1_

bash_import ./libb.bash=__NS__b2_

__NS__funa() {
	printf -- '%s\n' "funa with namespace '__NS__'";
}

__NS__funa
__NS__b1_funb
__NS__b2_funb
