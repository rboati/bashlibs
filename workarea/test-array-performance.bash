#/bin/bash

# Which is faster?
# indexed array expansion vs indirect expansion.

# indexed array expansion...
declare -ar LOGLEVELS=( OFF FATAL ERROR WARN INFO DEBUG TRACE )
declare -a  LOGCOLORS=( '0' '1;31' '31' '33' '34' '37'  '1' )

# indirect expansion...
declare -ir LOGLEVEL_INDEX_OFF=0
declare -ir LOGLEVEL_INDEX_FATAL=1
declare -ir LOGLEVEL_INDEX_ERROR=2
declare -ir LOGLEVEL_INDEX_WARN=3
declare -ir LOGLEVEL_INDEX_INFO=4
declare -ir LOGLEVEL_INDEX_DEBUG=5
declare -ir LOGLEVEL_INDEX_TRACE=6
declare -r  LOGLEVEL_NAME_0='OFF'
declare -r  LOGLEVEL_NAME_1='FATAL'
declare -r  LOGLEVEL_NAME_2='ERROR'
declare -r  LOGLEVEL_NAME_3='WARN'
declare -r  LOGLEVEL_NAME_4='INFO'
declare -r  LOGLEVEL_NAME_5='DEBUG'
declare -r  LOGLEVEL_NAME_6='TRACE'
declare -r  LOGLEVEL_COLOR_0='0'
declare -r  LOGLEVEL_COLOR_1='1;31'
declare -r  LOGLEVEL_COLOR_2='31'
declare -r  LOGLEVEL_COLOR_3='33'
declare -r  LOGLEVEL_COLOR_4='34'
declare -r  LOGLEVEL_COLOR_5='37'
declare -r  LOGLEVEL_COLOR_6='1'



declare -i i j LEVEL LOOP_1=100 LOOP_2=1000
time {
	for ((i=0; i<$LOOP_1; ++i )); do
		for (( LEVEL=0; LEVEL<7; ++LEVEL )); do
			for ((j=0; j<$LOOP_2; ++j )); do
				NAME=${LOGLEVELS[$LEVEL]}
				COLOR=${LOGCOLORS[$LEVEL]}
			done
		done
	done
} > /dev/null

time {
	for ((i=0; i<$LOOP_1; ++i )); do
		for (( LEVEL=0; LEVEL<7; ++LEVEL )); do
			VARNAME="LOGLEVEL_NAME_$LEVEL"
			VARCOLOR="LOGLEVEL_COLOR_$LEVEL"
			for ((j=0; j<$LOOP_2; ++j )); do
				NAME=${!VARNAME}
				COLOR=${!VARCOLOR}
			done
		done
	done
} > /dev/null

## Conclusion:
# indirect expansion is faster than indexed array expansion
# but it requires always(?) an additional assignment,
# so, considering an additional assignment also for the indexed array,
# the cost for the indexed array expansion happens only once,
# later the cost consists in that of simple word expansion.

