#!/bin/bash

# shellcheck disable=SC1091
source ../bashlibs.bash
DEBUG=1 bash_import ../libdata.bash -p db_


# declare -a def=( id name text  )

# declare -a array=( "one two three" "Hello
# 'World'"  )

# rm data.txt
# add_record data.txt def 1 Alice "Hello
# 'World'"
# add_record data.txt def 2 Bob "Hello
# 'World'"
# add_record data.txt def 3 Charlie "Hello
# 'World'"
# add_record data.txt def 4 Dan "Hello
# 'World'"

# add_record data.txt def 5 Elton "${array[*]@Q}"

# cat data.txt

# get_record data.txt def 4
# record_array=( $record_text )
# declare -p record_id
# declare -p record_name
# declare -p record_text
# declare -p record_array

declare -gA DB=( [file]=memory [vfs]=memdb )
db_open DB
#trap 'db_close DB' EXIT

{
	echo "--"

	db_query DB "CREATE TABLE n (id INTEGER PRIMARY KEY, name TEXT, text TEXT);"
	echo "--"
	db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('1', 'Alice', '\$Hello  \"to the\"   \n   ''world''');"
	echo "--"
	db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('2', 'Bob', 'Hello\nworld');"
	echo "--"
	db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('3', 'Charlie', 'Hello\nworld');"
	echo "--"
	db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('4', 'Dan', 'Hello\nworld');"
	echo "--"
	db_query DB "select * from n limit 1;"
	echo "--"
} #> /dev/null

declare -A record
retvar=record db_get_record DB "select * from n limit 1 offset 3"
echo "exit code = $?"
declare -p record
unset -v record


db_query DB "select * from n" 1
declare -A record
while retvar=record db_next DB; do
	declare -p record
	if [[ ${record[name]} == 'Bob' ]]; then
		echo "Found Bob"
		db_flush DB
	fi
done


db_close DB

