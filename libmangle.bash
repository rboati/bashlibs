

__NS__mangle_function() {
	pragma require_commands /bin/sed
	local name=${1:?} decl
	local -a sed_opts=( "${@:2}" )
	decl=$(declare -pf "$name" | sed "${sed_opts[@]}" )
	eval "$decl"
}

# It cannot clone correctly a recursive function
__NS__clone_function() {
	pragma require_commands /bin/cat
	local oldname=${1:?} newname=${2:?} decl
	local IFS=$' \t\n'
	decl=$(declare -pf "$oldname" | { read -r _; printf -- '%s ()\n' "$newname"; cat; })
	unset -f "$newname"
	eval "$decl"
}

# It cannot rename correctly a recursive function
__NS__rename_function() {
	pragma require_commands /bin/cat
	local oldname=${1:?} newname=${2:?} decl
	decl=$(declare -pf "$oldname" | { read -r _; printf -- '%s ()\n' "$newname"; cat; })
	unset -f "$oldname" "$newname"
	eval "$decl"
}

