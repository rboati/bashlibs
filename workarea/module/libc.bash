source as module
module.already_loaded && return

func() {
	printf -- '%s\n' "func"
}
