#!/bin/bash

# shellcheck disable=SC1091
source ../bashlibs.bash
DEBUG=1 bash_import ../libdata.bash -p db_

set_loglevel 6

# shellcheck disable=SC2034
declare -gA DB=( [file]=memory [vfs]=memdb )
db_open DB
trap 'printf "Closing DB...\n"; db_close DB' EXIT


db_query DB 'CREATE TABLE n (id INTEGER PRIMARY KEY, name TEXT, text TEXT);'
db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES (1, 'Alice'  , $(db_sql_quote "\$Hello  \"new\"   "$'\n'"   ''world''"));"
db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES (2, 'Bob'    , $(db_sql_quote 'Hello world'));"
db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES (3, 'Charlie', $(db_sql_quote 'Hello world'));"
db_query DB "INSERT INTO \"main\".\"n\" (\"id\", \"name\", \"text\") VALUES (4, 'Dan'    , $(db_sql_quote 'Hello world'));"

declare -A record
retvar=record db_get_record DB "select * from n limit 1;"
declare -p record


declare -A record
retvar=record db_get_record DB "select * from n limit 1 offset 3"
declare -p record
unset -v record

db_query DB "select id, name, text from n" 1
declare -A record
while retvar=record db_next DB; do
	declare -p record
	if [[ ${record[name]} == 'Bob' ]]; then
		echo "Found Bob"
		db_flush DB
	fi
done


db_close DB

