
PATH=.:$PATH

source as module ./libc.bash
source as module ./liba.bash

echo "---------------------"
declare -pF
declare -p | grep "^declare [^ ]\+ _[^=]"
alias