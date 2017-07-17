#! /bin/bash 

myname=${0##*/}

datefile=.${myname}.last

if	(( $# < 1 ))
then	echo 1>&2 "Usage: $myname <folder to check> ..."
	exit 1
fi

cd ~/Mail

countfiles()
{
	(cd $1
	 if	[ -f $datefile ]
	 then	find . -newer $datefile -type f -print | wc -l
	 else	find . -type f -print | wc -l
	 fi)
}

for	i in "$@"
do	if	[ -d $i ]
	then	files=$(countfiles $i)
		if	((files > 0))
		then	mailx -s  "$files new messages in ~/Mail/$i" mick <&-
		fi
		touch $i/$datefile
	else	echo 1>&2 "$myname: No ~/Mail folder named '$i'"
	fi
done
