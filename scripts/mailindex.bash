#! /bin/bash

# outputs to standard out an index of all the mail files found in numerical 
# order from the current direectory on down. A mail file is a file with a 
# name that is purely numeric, from 1 to 9999.

myname=${0##*/}
TMP=${myname}.$$

trap "rm -f $TMP" 1 2 3 15

prefix()
{
        while   read line
        do      echo "$1$line"
        done
}

cd $HOME/Mail

find . -type d -print | sort | while read dir
do      ls -1F "$dir" | egrep '^[0-9]+$' | sort -n | prefix "$dir"/
done >$TMP
mv -f $TMP mail.index

