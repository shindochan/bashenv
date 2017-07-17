#! /bin/bash

# USAGE:
# Usage: PROGRAM [-b][-f][-i][-m][-n][-r|-R][-s][-v]  [directory to scan ...]
# END USAGE

# HELP:

# where DIRECTORY_TO_SCAN is the root of a directory tree to scan for
# duplicate files.  Multiple directories may be specified, in which
# case all are scanned, and if no directory is specified, the search
# is rooted in the current working directory. 

# There are four comparisons to choose from. The option -f uses a
# whole file md5 sum, the -m options uses the md5 sum of the From: and
# Subject: headers of a mail message, the -i option uses the md5
# sum of the Message-Id header of a mail message, and the -b option
# uses the md5 sum of the message body. These last three options skip
# files that are not mail messages. Which files are considered mail
# messages varies for each option.

# This program produces a report of files and, unless -n is specified,
# their matching md5 checksums. Files are sorted by checksum and, if -s
# is specified, a short line of dashes separates groups of identical
# checksums. Note that if -n is specified without -s, there is no
# way to tell which files are duplicates.

# If either the -R or -r option is specified, the output is
# formatted as a script to remove duplicates. The -R option preserves
# the first file, the -r option preserves the last. At present, this
# will be by sort order.
 
# END HELP

prog=${0##*/}
prog=${prog%%_internal}
USAGE=$(sed -e '1,/^# USAGE:$/d' -e '/^# END USAGE$/,$d' -e 's/^# //' \
		-e "s PROGRAM $prog " $0)
HELP="$USAGE
$(sed -e '1,/^# HELP:$/d' -e '/^# END HELP/,$d'	 -e 's/^# //' \
	-e "s PROGRAM $prog " $0)"
USAGE="$USAGE
	Use any unused flag for more help"
# Variables set via command line options
NOMDID=
RM=
SEPARATE=
TYPE=file
VERBOSE=
SORT=

# Internal use variables

# process options
while getopts bfimnrRsv opt
do	case $opt in
	b)	TYPE=body ;;
        f)      TYPE=file ;;
        i)      TYPE=mid ;;
        m)      TYPE=message ;;
	n)	NOMID=true ;;
        r)      RM=true SORT=-r ;;
	R)	RM=true SORT= ;;
	s)	SEPARATE=true ;;
	v)	VERBOSE=true ;;
	\?)	echo "$HELP" 1>&2
		exit 1;;
	esac
done
shift $((OPTIND - 1))

# version 3.1:
prog=${0##*/}
if   (($# == 0))
then set . # make sure "$@" generates at least one argument
fi
omdid=
ofile=
matches=
md=$(type -path md5)
case $TYPE in
    body)	md5()
		{
		    mid="$(head -2 "$1"| tail -1 | grep '^[A-Za-z0-9-]\+: ')"
		    if   [[ -n $mid ]]
		    then echo "$(sed -e '1,/^$/d' "$1" |$md -q) $1"
		    fi
		} ;;
    file)	md5()
                {
                    $md -r "$1"
                } ;;
    message)	md5() 
                {
		    mid="$(sed -e '/^$/,$d' "$1" | egrep '^(From|Subject): ')"
		    if   [[ -n $mid ]]
		    then echo "$($md -qs "$mid") $1"
		    fi
		} ;;
    mid)	md5()
		{
		        mid="$(sed -e '/^$/,$d' "$1" | egrep '^Message-Id: ')"
			if   [[ -n $mid ]]
			then echo  "$($md -qs "$mid") $1"
			fi
		} ;;
esac

find "$@" -follow -type f -print | \
    while read file				# whole line
    do md5 "$file"
    done | sort $SORT | \
    while read mdid file
    do    if   [[ $mdid == $omdid ]]
          then # current file matches previous file
	       if   [[ -z $matches ]]
               then # Not yet in a match zone, start one.
		    if   [[ -n $RM ]]
		    then echo -n "# "
			 if   [[ $TYPE = message ]]
		         then echo -n $(sed -e '/^$/,$d' "$file" | egrep '^(From|Subject): ') " "
		         fi
		    fi
		    if   [[ -n $NOMID ]]
		    then echo $ofile
		    else echo $omdid $ofile
		    fi
                    matches=yes
               fi
	       # all match cases execute this code
	       if   [[ -n $RM ]]
	       then echo -n 'rm -f '
	       fi
	       if   [[ -n $NOMID ]]
	       then echo $file
	       elif [[ -n $RM ]]
	       then echo "'$file' # $mdid"
	       else echo $mdid $file
	       fi
	  else # current file is different from previous one
	       if   [[ -n $matches ]]
	       then # Have to end a match zone
		    [[ -n $SEPARATE ]] && echo '#--------'
	            matches=
	       fi
          fi
          omdid=$mdid
          ofile=$file
    done

# don't forget to add dupreport functionality
