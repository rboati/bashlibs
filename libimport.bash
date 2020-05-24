# Dependencies:
# cat, sed

(( ${#BASH_IMPORT[@]} != 0 )) && return

if [[ -z $BASH_LIBRARY_PATH ]]; then
	declare -g BASH_LIBRARY_PATH="$HOME/.local/lib/bash:/usr/local/lib/bash:/usr/lib/bash"
fi

declare -ga BASH_IMPORT_STACK=()

declare -gA BASH_IMPORT=( [$(readlink -e "${BASH_SOURCE[0]}")]='<empty>,' )

bash_import() {
	declare source_file="$1"
	declare ns="$2"
	shift 2
	declare item IFS
	declare -i found=0
	declare -a namespaces
	local import_type
	if [[ -z $__FILE__ ]]; then
		# shellcheck disable=SC2155
		declare __FILE__="$(readlink -e "$0")"
		declare __DIR__="${__FILE__%/*}"
	fi

	if [[ $source_file == /* ]]; then
		# absolute path
		import_type=absolute
		__FILE__="$source_file"
		found=1
	elif [[ $source_file == ./*  || $source_file == ../* ]]; then
		# relative path
		import_type=relative
		__FILE__="$__DIR__/$source_file"
		found=1
	else
		# search library path
		import_type=library
		declare IFS=':'
		for item in $BASH_LIBRARY_PATH; do
			if [[ -r $item/$source_file ]]; then
				__FILE__="$item/$source_file"
				found=1
				break
			fi
		done
		unset IFS
	fi
	if (( found == 1 )); then
		if ! __FILE__="$(readlink -e "$__FILE__")" || [[ -z $__FILE__ ]]; then
			found=0
		fi
	fi
	if (( found == 0 )); then
		(( LOGLEVEL >= 2 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' ERROR bash_import "Importing from ${import_type} path: '$source_file' not found! ($__FILE__)" 1>&2
		exit 1
	fi

	if [[ -n ${BASH_IMPORT[$__FILE__]} ]]; then
		IFS=',' read -r -a namespaces <<< "${BASH_IMPORT[$__FILE__]%,}"
		unset IFS
		for item in "${namespaces[@]}"; do
			if [[ ${ns:-<empty>} == "$item" ]]; then
				(( LOGLEVEL >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_import "Importing from ${import_type} path: '$source_file' already imported with namespace '${ns:-<empty>}', skipping." 1>&2
				return 2
			fi
		done
		if (( LOGLEVEL >= 5 )); then
			printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s' DEBUG bash_import "Importing from ${import_type} path: '$source_file' already imported with other namespaces (${BASH_IMPORT[$__FILE__]%,}), importing with " 1>&2
			if [[ -z $ns ]]; then
				printf '%s\n' "no namespace." 1>&2
			else
				printf '%s\n' "namespace \"$ns\"." 1>&2
			fi
		fi
	else
		(( LOGLEVEL >= 5 )) && printf '\e[37m%s\e[0m:\e[37m%s\e[0m:%s\n' DEBUG bash_import "Importing from ${import_type} path: '${source_file}'${ns:+ with namespace \"$ns\"}" 1>&2
	fi


	BASH_IMPORT_STACK+=( "$__DIR__" )
	__DIR__="${__FILE__%/*}"
	BASH_IMPORT[$__FILE__]+="${ns:-<empty>},"
	unset source_file item found namespaces
	if [[ -n $DEBUG ]] && (( DEBUG > 0 )); then
		local -r tmpdir="/tmp/$USER/libimport.bash/$$"
		mkdir -p "$tmpdir"
		sed -e "s/\<__[N]S__/${ns}/g" > "$tmpdir/${__FILE__##*/}" "$__FILE__"
		# shellcheck disable=SC1090
		source "$tmpdir/${__FILE__##*/}"
		(( DEBUG == 1 )) && rm -rf "$tmpdir"
	else
		eval "$(sed -e "s/\<__[N]S__/${ns}/g" "$__FILE__")"
	fi
	__DIR__="${BASH_IMPORT_STACK[-1]}"
	unset "BASH_IMPORT_STACK[-1]"
}

