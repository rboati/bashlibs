#/bin/bash

source "../libimport.bash"
bash_import "../libcolor.bash"


set_color256 "$(convert_rgb_to_palette256 0 0 67)" "$(convert_rgb_to_palette256 190 154 190)" 'bold,italic'
echo "set FG='$(convert_rgb_to_palette256 0 0 67)' BG='$(convert_rgb_to_palette256 190 154 190)' ATTR='bold,italic'"
unset_color 'XXXX' '' 'italic'
echo "unset FG='XXXX' ATTR='italic'"
unset_color

set_color16m '180;0;0' '190,154,190' 'bold' 'italic'
echo "set FG='180;0;0' BG='190,154,190' ATTR='bold,italic'"
unset_color '180;0;0' '' 'italic'
echo "unset FG='180;0;0' ATTR='italic'"
unset_color

echo

demo_color16m

echo

demo_color256

echo

demo_text_attributes

echo
