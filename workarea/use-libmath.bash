#!/bin/bash

# shellcheck disable=SC1091
source '../bashlibs.bash'

DEBUG=1 bash_import libmath.bash -p math_


declare -a hex_alphabet_arr dec_alphabet_arr
declare -Ai hex_alphabet_map dec_alphabet_map
math_make_base_alphabet hex_alphabet 0 1 2 3 4 5 6 7 8 9 a b c d e f
math_make_base_alphabet dec_alphabet 0 1 2 3 4 5 6 7 8 9
declare -p hex_alphabet_arr hex_alphabet_map dec_alphabet_arr dec_alphabet_map

declare result
retvar=result math_base_conv 'ff' hex_alphabet dec_alphabet
declare -p result
