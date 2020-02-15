
[[ -n $BASH_IMPORT ]] && return

if [[ -z $BASH_LIBRARY_PATH ]]; then
	declare -g BASH_LIBRARY_PATH="$HOME/.local/share/bash:/usr/local/share/bash:/usr/share/bash"
fi

declare -gA BASH_IMPORT=( ["$(readlink -e "$0")"]='<empty>,' )

bash_import() {
	declare SOURCE="$1"
	declare NS="$2"
	shift 2
	declare ITEM
	declare -i FOUND=0
	declare -a NAMESPACES
	if [[ -z $__FILE__ ]]; then
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
		declare __FILE__="$(readlink -e "$__FILE__")"
		if (( $? != 0)); then
			FOUND=0
		fi
	fi
	if (( FOUND == 0 )); then
		echo "$SOURCE not found! ($__FILE__)" 1>&2
		exit 1
	fi
	declare __DIR__="${__FILE__%/*}"
	if [[ -n ${BASH_IMPORT[$__FILE__]} ]]; then
		IFS=',' NAMESPACES=( ${BASH_IMPORT[$__FILE__]%,} )
		for ITEM in "${NAMESPACES[@]}"; do
			if [[ ${NS:-<empty>} == $ITEM ]]; then
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
	eval "$(cat "$__FILE__" | sed "s/\<__[N]S__/${NS}/g")"
}

