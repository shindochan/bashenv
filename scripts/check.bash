#! /bin/bash
# This program, in a CVS tree, will do a test checkout and generate file
# lists of the various sorts like C.check.<date> M.check.<date>, etc.
# 
# Needs the same args used at original checkout

NAME=${0##*/}
FULLYEAR=$(date)
FULLYEAR=${FULLYEAR##* }
OUT=$NAME.$FULLYEAR$(date +%m%d%H%M)

# Check that at least one arg given
if	(($# < 1))
then	echo 1>&2 "Usage: $NAME cvs-checkout-arg+"
	exit 1
fi

if	[ ! -d CVS ] && [ ! -d install/CVS ] && [ ! -d usr/CVS ]
then	echo 1>&2 $NAME: Current directory $(pwd) not a CVS view
	exit 2
fi

rm -f ${OUT}*
trap "rm -f ?.${OUT}*" 1 2 3 15
S="$NAME: (THIS IS A >>>TEST<<< CHECKOUT ONLY - NO FILES ARE MODIFIED)"
echo  2>&1 "$S"
cvs -n checkout "$@" | grep "^[^?]"  | while	read status file rest
do	echo "$file" >>$status.$OUT
done	
