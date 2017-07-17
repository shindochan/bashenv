#! /bin/bash
for file in "$@"
do
  for db in $(sed -e '/^USE/!d' -e 's/^USE `//' -e 's/`;.*$//' $file)
  do
    export DB=$db
    [[ -d $DB ]] || mkdir $DB || exit 1
    for table in $(sed -e "/^USE .$DB/,/^USE /"'!d' -e '/^CREATE TABLE/!d' -e 's/^.* `//' -e 's/` .*$//' $file)
    do echo extracting table definition for  $DB.$table
      sed -e "/CREATE TABLE \`$table\`/,/;/!d" $file >$DB/$table
    done
  done
done
