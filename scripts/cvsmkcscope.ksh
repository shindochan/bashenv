#! /bin/ksh

if	(($# > 1))
then	echo "Usage: ${0##*/} [cscope-prefix]"
fi

if	(($# == 1))
then	NAME=$1
else	NAME=cscope
fi

find . -name CVS -prune -o -type f -print | sort -u > $NAME.allfiles
find . -name CVS -prune -o -type d -print | sort -u > $NAME.alldirs

# Now, find the names of all derived files and directories . . . 
cvs -n update 2>$NAME.cvserrs | sed -e '/^? /!d' -e 's,^? ,./,' | \
    sort -u >$NAME.derived

# Create a list of derived directories
comm -12 $NAME.alldirs $NAME.derived >$NAME.deriveddirs

# Create an initial list of derived files
comm -12 $NAME.allfiles $NAME.derived >$NAME.derivedfiles

# add into it all files in derived directories
for	dir in $(< $NAME.deriveddirs)
do	grep "^$dir/" $NAME.allfiles
done	>> $NAME.derivedfiles

# resort
sort -u -o $NAME.derivedfiles $NAME.derivedfiles

# Now, create a list of all non-derived files:
comm -23 $NAME.allfiles $NAME.derivedfiles >$NAME.files
if	[ -z "$DEBUG" ]
then	rm $NAME.derived* $NAME.all*
fi

cscope -b -q -f $NAME.out -i $NAME.files
