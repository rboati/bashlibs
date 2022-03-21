#!/bin/bash

set -u

# shellcheck disable=SC1091
source ../libimport.bash
bash_import ../libutils.bash

trap -- "echo aaa" USR1

declare return
add_trap "echo ciao" USR1
echo "$return"
add_trap "echo mondo" USR1
echo "$return"

kill -s USR1 $$

trap -p USR1

#sleep 100