#! /bin/ksh

if	(($# > 1))
then	echo "Usage: ${0##*/} [cscope-prefix]"
fi

if	(($# == 1))
then	NAME=$1
else	NAME=cscope
fi

# Sort files separately so all includes are at the top

echo . >$NAME.dirs

find $(<$NAME.dirs) -follow \( -name '*.[chlyCGHLwsT]' -o -name '*.bp' -o \
        -name '*.q[ch]' -o -name '*.sd' -o -name '*.mk' -o \
        -name '*.java' -o -name '*.xml' -o -name '*.js' -o \
        -name '*.cfg' -o -name '*.css' -o -name '*.jsp' -o \
        -name '*.rb' -o -name '*.php' -o -name '*.cpp' -o \
        -name '[Mm]akefile' -o -name '*.cc' \) -print | sort -u >$NAME.tmp

# Now, find the names of all derived files . . . 
egrep "\.w$" <$NAME.tmp | 
while	read file
do	dir=${file%/*}
	sed -e '/^@output/!d' -e 's/@output[ 	]*//' -e 's/[ 	].*$//' \
	    -e "s,^,$dir/," -e 's,/[^/][^/]*//*\.\./,/,g' $file
done  | sort -u >$NAME.dups

# . . . and remove them. Quote every line, too, to encapsulate spaces.
comm -23 $NAME.tmp $NAME.dups | sed -e 's/^\(.*\)$/"\1"/' >$NAME.files
rm $NAME.tmp
cscope -b -q -f $NAME.out -i $NAME.files
