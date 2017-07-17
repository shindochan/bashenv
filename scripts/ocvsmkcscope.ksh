#! /bin/ksh

if	(($# > 1))
then	echo "Usage: ${0##*/} [cscope-prefix]"
fi

if	(($# == 1))
then	NAME=$1
else	NAME=cscope
fi

echo . >$NAME.dirs

find $(cat $NAME.dirs) \( -name '*.[chlyCGHLws]' -o -name '*.bp' -o \
	-name '*.q[ch]' -o -name '*.sd' -o -name '*.mk' -o \
	-name '[Mm]akefile' -o -name '*.cc' \) -print | sort -u >$NAME.tmp

# Now, find the names of all derived files . . . 
cvs -n update 2>$NAME.cvserrs | sed -e '/^? /!d' -e 's,^? ,./,' | \
sort -u >$NAME.derived

# . . . and remove them
comm -23 $NAME.tmp $NAME.derived >$NAME.files
[ -z "$DEBUG" ] && rm $NAME.tmp
cscope -b -q -f $NAME.out -i $NAME.files
