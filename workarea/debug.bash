#/bin/bash



DEBUG=1
source "../libimport.bash"
bash_import "libdebug.bash" __NS__


if [[ -n "$1" ]]; then
	__DEBUG_FILE__="$(readlink -e "$1")"
	shift
	__NS__set_debugger_property color 1
	__NS__set_debugger_property locals.auto 1
	__NS__set_debugger_property watch.auto 1
	__NS__add_data_breakpoint "[[ \"\$(readlink -m \"\${BASH_SOURCE[1]}\")\" == \"${__DEBUG_FILE__}\" ]] && __NS__delete_data_breakpoint 0 && __NS__STEPMODE=1"
	__NS__STEPMODE=0
	__NS__set_debugger_trap
	source "$__DEBUG_FILE__" "$@"
	wait
	exec 0<&10 1>&11 2>&12 # set stdin, stdout, stderr
	exec 10<&- 11>&- 12>&- # close copies of stdin, stdout, stderr
fi
