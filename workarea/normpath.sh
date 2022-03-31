#!/bin/bash

source ../bashlibs.bash
bash_import libfile.bash



perf() {
	local -i c=100
	local normpath
	printf '\nExecuting %d normpath with var output...' $c
 	time while (( c > 0 )); do
		for i in "${!input_a[@]}"; do
			normpath "${input_a[i]}"
			if [[ $normpath != "${expected_a[i]}" ]]; then
				printf 'Mismatch! "%s" != "%s" \n' "$normpath" "${expected_a[i]}"
				exit
			fi
		done
		(( c -= 1 ))
	done
}


main() {
	local input_a=(    ''  '/..'  '/../'  '.'  '/./' './'  '..'  '../'  '../abc/def'  '../abc/def/..'  '../abc/././././def/..'  '////../abc/def'  '/../def'  '../def'  '/abc////../def'  'abc/../def/ghi'  '/abc/def/../ghi'  '/abc/..abc////../def'  '/abc/..abc/../def'  'abc/../def'  'abc/../../def'  '././'  'abc/..'  'abc/../'  'abc/../..'  'abc/../../'  'a/..'  'a/../'  'a/../..'  'a/../../'  '../../../a'  '../a../../a'  'cccc/abc////..////.//../'  'aaaa/cccc/abc////..////.//../'  '..//////.///..////..////.//////abc////.////..////def//abc/..'  '////////////..//////.///..////..////.//////abc////.////..////def//abc/..' )
	local expected_a=( '.' '/'    '/'     '.'  '/'   '.'   '..'  '..'   '../abc/def'  '../abc'         '../abc'                 '/abc/def'        '/def'     '../def'  '/def'            'def/ghi'         '/abc/ghi'         '/abc/def'              '/abc/def'           'def'         '../def'         '.'     '.'       '.'        '..'          '..'         '.'     '.'      '..'       '..'        '../../../a'  '../a'         '.'                         'aaaa'                           '../../../def'                                                  '/def'                                                                     )
	local -i i
	local input expected output color
	local normpath=

	#normpath '/abc////../def'; exit


	printf '%80s   %15s   %s\n' "INPUT" "EXPECTED" "OUTPUT"
 	for i in "${!input_a[@]}"; do
	 	input=${input_a[i]}
		expected=${expected_a[i]}
		normpath "$input"
		output=$normpath
		if [[ $output != "$expected" ]]; then
			color='\e[31m'
		else
			color='\e[32m'
		fi
		printf "$color%80s\e[0m | $color%15s\e[0m | $color%s\e[0m\n" "$input" "$expected" "$output"
	done

	perf
}

main
