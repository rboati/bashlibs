#!/bin/bash

source ../bashlibs.bash
bash_import libfile.bash



main() {
	local input_a=(    ''  '/..'  '/../'  '.'  '/./' './'  '..'  '../'  '../abc/def'  '../abc/def/..'  '../abc/././././def/..'  '////../abc/def'  '/../def'  '../def'  '/abc////../def'  'abc/../def/ghi'  '/abc/def/../ghi'  '/abc/..abc////../def'  '/abc/..abc/../def'  'abc/../def'  'abc/../../def'  '././'  'abc/..'  'abc/../'  'abc/../..'  'abc/../../'  'a/..'  'a/../'  'a/../..'  'a/../../'  '../../../a'  '../a../../a'  'cccc/abc////..////.//../'  'aaaa/cccc/abc////..////.//../'  '..//////.///..////..////.//////abc////.////..////def//abc/..'  '////////////..//////.///..////..////.//////abc////.////..////def//abc/..' '///////////' )
	local expected_a
	mapfile -t expected_a < <(dirname "${input_a[@]}")
	local -i i
	local input expected output color
	local posix_dirname

	printf '%80s   %15s   %s\n' "INPUT" "EXPECTED" "OUTPUT"
 	for i in "${!input_a[@]}"; do
	 	input=${input_a[i]}
		expected=${expected_a[i]}
		posix_dirname "$input"
		output=$posix_dirname
		if [[ $output != "$expected" ]]; then
			color='\e[31m'
		else
			color='\e[32m'
		fi
		printf "$color%80s\e[0m | $color%15s\e[0m | $color%s\e[0m\n" "$input" "$expected" "$output"
	done

}

main
