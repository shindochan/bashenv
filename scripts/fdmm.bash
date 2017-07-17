#! /bin/bash
echo 1>&2 No usage yet, writes to stdout, informational only
echo 1>&2 needs options for list all files

# version 2.0:
myname=${0##*/}

dirs="$@"

omdid=
ofile=
matches=
messageID()
{
    echo $(md5 -qs "$(sed -e '/^$/,$d' "$1" | egrep '^(From|Subject): ')") "$1"
}

find ${dirs:-.} -follow -type f -print | \
    while read file				# whole line
    do messageID "$file"
    done | sort | \
    while read mdid file
    do    if   [[ $mdid == $omdid ]]
          then if   [[ -z $matches ]]
               then echo $omdid $ofile
                    matches=yes
               fi
	       echo $mdid $file
	  else if   [[ -n $matches ]]
	       then echo --------
	            matches=
	       fi
          fi
          omdid=$mdid
          ofile=$file
    done
