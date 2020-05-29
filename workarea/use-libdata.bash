#!/bin/bash

# shellcheck disable=SC1091
source ../libimport.bash
DEBUG=1 bash_import ../libdata.bash


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
open_db DB
{
	echo "--"
	query DB "CREATE TABLE n (id INTEGER PRIMARY KEY, name TEXT, text TEXT);"
	echo "--"
	query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('1', 'Alice', '\$Hello  \"to the\"   \n   ''world''');"
	echo "--"
	query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('2', 'Bob', 'Hello\nworld');"
	echo "--"
	query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('3', 'Charlie', 'Hello\nworld');"
	echo "--"
	query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES ('4', 'Dan', 'Hello\nworld');"
	echo "--"
	query DB "select * from n limit 1;"
	echo "--"
} > /dev/null

get_record DB "select * from n limit 1 offset 3"
echo "exit code = $?"
declare -p record_id
declare -p record_name
declare -p record_text
echo -e "<$record_text>"
unset record_id record_name record_text

declare -A record
get_record_map DB "select * from n limit 1 offset 3"
echo "exit code = $?"
declare -p record
unset record


declare -a record_id record_name record_text
get_records DB "select * from n"
echo "exit code = $?"
declare -p record_id
declare -p record_name
declare -p record_text
unset record_id record_name record_text

while iter_record DB "select * from n"; do
	declare -p record_id
	if [[ $record_name == 'Bob' ]]; then
		echo "Found Bob"
		declare -p record_id
		declare -p record_name
		declare -p record_text
		flush_iter DB
	fi
done

echo "--"

while iter_record DB "select * from n"; do
	declare -p record_id
	if [[ $record_name == 'Dan' ]]; then
		echo "Found Dan"
		declare -p record_id
		declare -p record_name
		declare -p record_text
		flush_iter DB
	fi
done



close_db DB


