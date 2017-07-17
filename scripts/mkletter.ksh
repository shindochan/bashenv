#! /bin/ksh
for i in $*
do 	file=$(basename $(basename $(basename $i "\.n") "\.l") "\.")
	if	[ -f $file.n ]
	then	nroff tmac.l $file.n >$file.l
	else	echo Cannot open $file.n
	fi
done
