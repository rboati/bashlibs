

__NS__mangle_function() {
	local name=${1:?} decl
	local -a sed_opts=( "${@:2}" )
	decl=$(declare -pf "$name" | sed "${sed_opts[@]}" )
	unset -f "$newname"
	eval "$decl"
}

__NS__clone_function() {
	local oldname=${1:?} newname=${2:?} decl
	decl=$(declare -pf "$oldname" | { read -r _; printf -- '%s ()\n' "$newname"; cat; })
	unset -f "$newname"
	eval "$decl"
}

__NS__rename_function() {
	local oldname=${1:?} newname=${2:?}
	__NS__clone_function "$@"
	unset -f "$oldname"
}
