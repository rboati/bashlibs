#!/bin/bash

# shellcheck disable=SC1091
source ../libimport.bash

bash_import "./lib.bash"

hello
hello2

bash_import "./lib.bash" mylib_

mylib_hello
mylib_hello2

bash_import "./lib.bash" mylib2_

mylib2_hello
mylib2_hello2

bash_import "./lib.bash"

bash_import "./lib.bash" mylib_


