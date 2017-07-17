#! /bin/bash

if	(($# > 1))
then	echo "Usage: ${0##*/} [cscope-prefix]"
fi

if	(($# == 1))
then	NAME=$1
else	NAME=cscope
fi

REPOSITORY=$(cat <CVS/Repository)

if	[ "${REPOSITORY##/}" = $REPOSITORY ]
then	# Make relative path absolute
	REPOSITORY=$(cat <CVS/Root)/$REPOSITORY
fi

if	[ -z "$REPOSITORY" ]
then	echo 1>&2 "Not in a CVS subtree!"
	exit 1
fi

(builtin cd $REPOSITORY; find . -name \*,v -print) | \
sed -e 's/,v$//' | sort -u > $NAME.files.cvs

find . -follow \( -name '*.[chlyCGHLws]' -o -name '*.bp' -o \
	-name '*.q[ch]' -o -name '*.sd' -o -name '*.mk' -o \
	-name '[Mm]akefile' -o -name '*.cc' \) -print | \
	sort -u > $NAME.files.local

comm -12 $NAME.files.cvs $NAME.files.local >$NAME.files

cscope -b -q -f $NAME.out -i $NAME.files
