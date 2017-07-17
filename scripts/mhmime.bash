#!/bin/bash

# TO FIX: if the name is the same offer to delete existing name, and always
# do so if -f is used. 

# single arg is both file and message number.
if	[ $# != 1 ]
then	echo 1>&2 "Usage: ${0##*/} <message number and file name>"
	exit 1
fi

MSG=$1
set_boundary()
{
	candidate=${1##Content-Type:*[bB][oO][uU][nN][dD][aA][rR][yY]='"'}
	if	[ "$candidate" != "$1" ]
	then	boundary=${candidate%%'"'*}
		echo "boundary='$boundary'"
	fi
}
link_file()
{
	file=
	candidate=${1##Content-Type:*name='"'}
	if	[ "$candidate" != "$1" ]
	then	file=${candidate%%'"'*}
	fi
	candidate=${1##Content-Type:*name=}
	if	[ -z "$file" -a "$candidate" != "$1" ]
	then	file=${candidate%%[ ;]*}
	fi
	candidate=${1##Content-Disposition:*filename='"'}
	if	[ -z "$file" -a "$candidate" != "$1" ]
	then	file=${candidate%%'"'*}
	fi
	candidate=${1##Content-Disposition:*filename=}
	if	[ -z "$file" -a "$candidate" != "$1" ]
	then	file=${candidate%%[ ;]*}
	fi
	set $MSG.$2.*
	if	(($# == 1))
	then	if	[ -f "$1"  -a -n "$file" ]
		then	if	[ "${filenames%%:${file}:*}" != "$filenames" ]
			then	: # alreay linked this name for this part.
			else	if	[ "${allfilenames%%:${file}:*}" != \
					  "$allfilenames" ]
				then	# file exists, but was from a previous
					# part, make it unique.
					file="$file.part$2"
				fi
				if	[ -f "$file" ]
				then	echo "Removing old '$file'"
					rm "$file"
				fi
				echo ln $1 "'$file'"
				ln $1 "$file"
				filenames="${filenames}${file}:"
				allfilenames="${allfilenames}${file}:"
		        fi
		fi
	fi
}

if	[ ! -f $MSG ]
then	ln -s ~/Mail/inbox/$MSG .
fi
mhstore $MSG

header=
state=headers
boundary=
((part = 0))
((filepart = 0))
filenames=":"
allfilenames=":"

while IFS= read line
do
	case $state in
	headers)
		if	[ "${line##[ 	]}" != "$line" ]
		then	header="$header $line"
		else	# new header, process old one first
			if	((part == 0))
			then	set_boundary "$header"
			else	if	((filepart != part))
				then	filenames=":"
					((filepart = part))
				fi
				link_file "$header" $part
			fi
			header="$line"
			if	[ -z "$header" ]
			then	state=body
			fi
		fi
		;;
	body)
		if	[ "${line##--${boundary}--}" != "$line" ]
		then	if	((parts == 1))
			then	S=
			else	S=s
			fi
			echo Done, read $part part$S
			exit 0
		fi
		if	[ "${line##--$boundary}" != "$line" ]
		then	((part = part + 1))
			state=headers
			echo Found part $part
		fi
		;;
	esac
done <$MSG
echo 'fell off end!'
exit 2
