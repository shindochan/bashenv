#! /bin/bash
# Given a single argument of a directory name, make it flat. Requires
# that the configured directory is on the same file system and same tree
# as usr.

BOOTDIR=$1/boot

if	cd $BOOTDIR
then	:
else	echo 1>&2 Bad directory '"'$BOOTDIR'"'
fi

ln -s  ../../../../../xenv.bin .
mkdir logs
chmod 1777 bin logs

(cd primary;ln -s C/* .)
(cd primary;for file in MTA_*;do ln -s $file TERA_${file##MTA_};done)

