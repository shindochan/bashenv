#! /bin/sh

# This program gives a du -a of ., with 10% and 1% marks and files of
# 1 block or less suppressed.

TMP=/tmp/dua.$$

trap "rm -f $TMP; exit 0" 0 1 2 3 15

du -a . >$TMP
all=`tail -1 $TMP | sed -e 's/	.*//'`
echo "`expr \( $all + 9 \) / 10`	is 10%" >>$TMP
echo "`expr \( $all + 99 \) / 100`	is 1%"  >>$TMP
shorts=`egrep "^[012]	" $TMP | wc -l`
zeros=`egrep "^0	" $TMP | wc -l`

egrep -v "^[012]	" $TMP | sort -r -n 
echo "$shorts files of two blocks or less omitted, $zeros of them empty"
