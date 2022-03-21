
__NS__normpath() {
	local path
	local -a path_arr
	local -i is_absolute
	local -i i

	while (( $# > 0 )); do
		path=$1
		shift
		if [[ $path != '' ]]; then
			path=$path/
		fi

		if [[ $path == /* ]]; then
			is_absolute=1
		else
			is_absolute=0
		fi

		IFS='/' read -ra path_arr <<< "${path}"

		# Remove all empty and . elements
		for i in "${!path_arr[@]}"; do
			if [[ ${path_arr[i]} == '.' || ${path_arr[i]} == '' ]]; then
				unset 'path_arr[i]'
			fi
		done

		# For absolute path remove also all leading .. elements
		if (( is_absolute == 1 )); then
			for i in "${!path_arr[@]}"; do
				if [[ ${path_arr[i]} == '..' ]]; then
					unset 'path_arr[i]'
				else
					break
				fi
			done
		fi

		# Remove each pair parent/..
		while :; do
			path_arr=( "${path_arr[@]}" )
			for i in "${!path_arr[@]}"; do
				if [[ (${path_arr[i]} != '..') && ( ${path_arr[i+1]} == '..' ) ]]; then
					unset 'path_arr[i]'
					unset 'path_arr[i+1]'
					continue 2
				fi
			done
			break
		done

		printf -v path '/%s' "${path_arr[@]}"

		if (( is_absolute != 1 )); then
			path=${path#/}
			if [[ -z $path ]]; then
				path=.
			fi
		fi
		# shellcheck disable=SC2034
		__NS__normpath=$path
	done
}


__NS__filecopy() {
	local src=$1 dst=$2
	local target=$dst
	local -i n=0
	while [[ -f $target ]]; do
		target="${dst}_$((++n))"
	done
	cp --no-dereference --preserve=all -- "$src" "$target"
	# shellcheck disable=SC2034
	__NS__filecopy=$target
}

__NS__filemove() {
	local src=${1:?} dst=${2:?}
	local target=$dst
	local -i n=0
	while [[ -f $target ]]; do
		target="${dst}_$((++n))"
	done
	mv -- "$src" "$target"
	# shellcheck disable=SC2034
	__NS__filemove=$target
}


__NS__template_copy() {
	local src=${1:?} dst_basedir=${2:-/}
	local -i exit_code=0
	# shellcheck disable=SC1090,SC2155
	local dst
	local __NS__normpath
	eval dst="$src"
	dst=${dst%.$}
	#dst=$(__NS__normpath "${dst_basedir}")/${dst#*/./}
	__NS__normpath "${dst_basedir}"
	dst=${__NS__normpath}/${dst#*/./}
	local dstdir
	dstdir="${dst%/*}"
	mkdir -p "$dstdir"
	local tmpfile=$dstdir/.${dst##*/}~

	if [[ $src == *.\$ ]]; then
		# shellcheck disable=SC1090
		( cd -- "${dstdir}" || exit 1; source "$src" )
	else
		cat -- "$src"
	fi  > "$tmpfile"

	exit_code=$?
	if (( exit_code != 0 )); then
		rm -- "$tmpfile"
		return 1
	fi

	if [[ -f $dst ]]; then
		if cmp -s -- "$tmpfile" "$dst"; then
			rm -- "$tmpfile"
			return 0
		fi
		__NS__filemove "$dst" "${dst}.bak"
	fi
	mv -- "$tmpfile" "$dst"
	chmod --reference="$src" -- "$dst"
	chown --reference="$src" -- "$dst"
}

__NS__posix_dirname() {
	local target=$1
	if [[ $target == '' ]]; then
		__NS__posix_dirname=.; return
	fi
	if [[ $target == '/' ]]; then
		__NS__posix_dirname=/; return
	fi
	while [[ $target == */ ]]; do
		target=${target%/}
	done
	__NS__posix_dirname=${target%/*}
	while [[ $__NS__posix_dirname == */ ]]; do
		__NS__posix_dirname=${__NS__posix_dirname%/}
	done
	if [[ $__NS__posix_dirname == '' ]]; then
		__NS__posix_dirname=/; return
	fi
	if [[ $target == "$__NS__posix_dirname" ]]; then
		__NS__posix_dirname=.; return
	fi
	return
}
