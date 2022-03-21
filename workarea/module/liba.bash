source as module
module.already_loaded && return

source as module ./libb.bash


funa() {
	printf -- '%s\n' "funa";
}

