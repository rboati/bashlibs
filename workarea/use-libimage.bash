#!/bin/bash

source "../libimport.bash"
bash_import "../libimage.bash"


ATTR='bold,italic' printf16m '%s\n' "Text demo 16 milions colors"
cat << EOF | fmt -66 -s

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
EOF
set_cursor_up 10
set_cursor_right 15
image16m "example.jpg" "100x"
echo

ATTR='bold,italic' printf256 '%s\n' "Text demo 256 colors"
cat << EOF | fmt -66 -s

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
Lorem ipsum
EOF
set_cursor_up 10
set_cursor_right 15
image256 "example.jpg" "100x"
echo

