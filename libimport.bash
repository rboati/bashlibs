# Dependencies:
# cat, sed

(( ${#BASH_IMPORT[@]} != 0 )) && return

if [[ -z $BASH_LIBRARY_PATH ]]; then
	declare -g BASH_LIBRARY_PATH="$HOME/.local/lib/bash:/usr/local/lib/bash:/usr/lib/bash"
fi

declare -gA BASH_IMPORT=( [$(readlink -e "${BASH_SOURCE[0]}")]='<empty>,' )

bash_import() {
	declare SOURCE="$1"
	declare NS="$2"
	shift 2
	declare ITEM IFS
	declare -i FOUND=0
	declare -a NAMESPACES
	if [[ -z $__FILE__ ]]; then
		# shellcheck disable=SC2155
		declare __FILE__="$(readlink -e "$0")"
		declare __DIR__="${__FILE__%/*}"
	fi

	if [[ $SOURCE == /* ]]; then
		# absolute path
		echo -n "Importing from absolute path: " 1>&2
		__FILE__="$SOURCE"
		FOUND=1
	elif [[ $SOURCE == ./*  || $SOURCE == ../* ]]; then
		# relative path
		echo -n "Importing from relative path: " 1>&2
		__FILE__="$__DIR__/$SOURCE"
		FOUND=1
	else
		# search library path
		echo -n "Importing from library path: " 1>&2
		declare IFS=':'
		for ITEM in $BASH_LIBRARY_PATH; do
			if [[ -r $ITEM/$SOURCE ]]; then
				__FILE__="$ITEM/$SOURCE"
				FOUND=1
				break
			fi
		done
		unset IFS
	fi
	if (( FOUND == 1 )); then
		if ! __FILE__="$(readlink -e "$__FILE__")" || [[ -z $__FILE__ ]]; then
			FOUND=0
		fi
	fi
	if (( FOUND == 0 )); then
		echo "$SOURCE not found! ($__FILE__)" 1>&2
		exit 1
	fi
	__DIR__="${__FILE__%/*}"

	if [[ -n ${BASH_IMPORT[$__FILE__]} ]]; then
		IFS=',' read -r -a NAMESPACES <<< "${BASH_IMPORT[$__FILE__]%,}"
		unset IFS
		for ITEM in "${NAMESPACES[@]}"; do
			if [[ ${NS:-<empty>} == "$ITEM" ]]; then
				echo "$SOURCE" "already imported with namespace \"${NS:-<empty>}\", skipping." 1>&2
				return 2
			fi
		done
		echo -n "$SOURCE" "already imported with other namespaces (${BASH_IMPORT[$__FILE__]%,}), importing with " 1>&2
		if [[ -z $NS ]]; then
			echo "no namespace." 1>&2
		else
			echo "namespace \"$NS\"." 1>&2
		fi
	else
		echo "${SOURCE}${NS:+ with namespace \"$NS\"}" 1>&2
	fi

	BASH_IMPORT[$__FILE__]+="${NS:-<empty>},"
	unset SOURCE ITEM FOUND NAMESPACES
	if [[ -n $DEBUG ]] && (( DEBUG > 0 )); then
		local -r tmpdir="/tmp/$USER/libimport.bash/$$"
		mkdir -p "$tmpdir"
		sed -e "s/\<__[N]S__/${NS}/g" > "$tmpdir/${__FILE__##*/}" "$__FILE__"
		# shellcheck disable=SC1090
		source "$tmpdir/${__FILE__##*/}"
		(( DEBUG == 1 )) && rm -rf "$tmpdir"
	else
		eval "$(sed -e "s/\<__[N]S__/${NS}/g" "$__FILE__")"
	fi
}

