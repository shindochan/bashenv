#! /bin/ksh

# pushln--if arg is a symlink to a dir, replace it with a directory of
# the same name with symlinks to the contents.  Otherwise, do a cpln.

TMP=./pushln$$
pwd >/dev/null			# set up PWD

# USAGE:
# Usage: PUSHLN [-a] [-d] path ...
# END USAGE

# HELP:
# If path is a symlink to a dir, replace it with a directory of
# the same name with symlinks to the contents.  If path is symlink to
# a file, replace the symlink with a copy of the file. Otherwise, do
# nothing.

# The -d option pushes all directories from each path, leaving only
# links to regular files.

# The -a option pushes all links, leaving no symbolic links at all. 

# END HELP

USAGE=`sed -e '1,/^# USAGE:$/d' -e '/^# END USAGE$/,$d' -e 's/^# //'  \
		-e "s/PUSHLN/${0##*/}/g" $0`
HELP="$USAGE
`sed -e '1,/^# HELP:$/d' -e '/^# END HELP/,$d'  -e 's/^# //' $0`"
USAGE="$USAGE
	Use any unused flag for more help"

DOALLDIRS=
DOALLLINKS=
type=
while getopts ad opt
do	case $opt in
	a)	DOALLLINKS=true
		type=f ;;
	d)	DOALLDIRS=true
		type=d ;;
	\?)	echo "$HELP" | ${PAGER-/usr/bin/more} 1>&2
		exit 1 ;;
	esac
done
shift `expr $OPTIND - 1`

if	[[ -n $DOALLLINKS ]]
then	DOALLDIRS=true
	type=f
fi

# process arguments
if	(($# == 0))
then	echo "$USAGE" 1>&2
	exit 1
fi

if	[[ -n $DOALLDIRS ]]
then	# This changes the meaning of things. For each mentioned dir,
	# expand it into all possible dirs and recurse.
	for	i in "$@"
	do	prefix= dirlist=
		find $i -follow -type $type -depth -print | while read dir
		do	if	[[ -z $prefix ]]
			then	prefix=${dir%/*}
			fi
			if	[[ $prefix = ${dir%/*} ]]
			then	if	[[ -z $dirlist ]]
				then	dirlist=$dir
				else	dirlist="$dirlist $dir"
				fi
			else	$0 $dirlist
				prefix=${dir%/*}
				dirlist=$dir
			fi
		done
	done
	if	[[ -n $dirlist ]]
	then	$0 $dirlist
	fi
	if	[[ -z $DOALLLINKS ]]
	then		exit
	fi
fi

if	[[ -n $DOALLLINKS ]]
then	# This is another change in the meaning of things. All
	# directories have already been done above, as well as one
	# file per directory. Now, just get the rest.
	find $@ -type l -print | xargs $0
	exit
fi

for i in "$@"
do	dirstack=

	dir=${i%/}		# remove trailing '/'
	dir=${dir#./}		# remove leading './'

	if	[[ ${dir#/} = $dir ]]
	then	LASTLINK=.	# relative path, starts with current dir
	else	LASTLINK=/	# absolute path, starts with root.
	fi

	# Break the path up into a stack of directories
	while	[[ -n "$dir" ]]
	do	dirstack="$dir $dirstack"
		newdir=${dir%/*}
		if	[[ "$newdir" = "$dir" ]]
		then	dir=
		else	dir=$newdir
		fi
	done

	# Traverse the path, one directory at a time, copying links as needed
	for	LINK in $dirstack
	do	if	[[ -L $LINK ]]
		then	mv $LINK $TMP
			if	[[ -d $TMP ]]
			then	mkdir $LINK
				PREFIX=`ls -l $TMP |
						sed -e 's/.*-> //' -e 's,/$,,'`
				/bin/ls -a1 $PREFIX |
				while	read DIRENT
				do	case "$DIRENT" in
					.|..)	;;
					*)	ln -s $PREFIX/$DIRENT $LINK ;;
					esac
				done
			else	cp $TMP $LINK
			fi
			
			rm -f $TMP
			
		fi
		LASTLINK=$LINK
	done
done
