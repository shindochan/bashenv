#! /bin/bash
# Find Duplilcate MesssageIDs AND Link
# Generates a report on stdout, generates a dirtree at /tmp/$myname
# version 2.0:
myname=${0##*/}

echo Find Duplilcate MesssageIDs AND Link
echo Generates a report on stdout
echo Generates a dirtree at /tmp/$myname. 
echo Each /tmp/$myname/subdir is a MessageID hash
echo Each file is a symlink to one of the messages with that MessageID hash

dirs="$@"

messageID()
{
    mid=$(sed -e '/^$/,$d' "$1" | egrep '^Message-Id: ')
    if   [[ -n $mid ]]
    then echo  $(md5 -qs "$mid")
    fi
}

tree=/tmp/$myname
tmp=${tree}.$$

if   [[ -e $tree ]]
then echo rm -rf $tree before running
     exit
fi
mkdir $tree
nmid=0
nfiles=0
ndups=0
find ${dirs:-.} -type f -print | while read file
do  # convert relative to absolute path
    if   [[ $file = ${file##/} ]]
    then file="$PWD/$file"
    fi
    mid=$(messageID "$file")
    if   [[ -n $mid ]]
    then if   [[ ! -e $tree/$mid ]]
         then ln -s "$file" $tree/$mid
              ((nmid++))
         elif   [[ ! -d $tree/$mid ]]
         then # file exists, not dir, must be a link, turn it into a dir
              oldfile="$(readlink -n $tree/$mid)"
              rm -f $tree/$mid
              mkdir -p $tree/$mid 
              ln -s "$oldfile" "$file" $tree/$mid
              ((ndups++))
         else ln -s "$file" $tree/$mid
              ((ndups++))
         fi
         ((nfiles++))
         if   ((nfiles%10 == 0 ))
         then echo -n .
         fi
         echo $nfiles $nmid $ndups >$tmp
    fi
done
echo
read nfiles nmid ndups <$tmp
rm -f $tmp
echo $nfiles messages $nmid distinct message IDs $ndups duplicate messages
echo Mean duplication rate $msg $(echo $nfiles $nmid 9k/pq|dc)
find $tree -type d -print | sed -e 1d | while read dir 
do echo $(ls -1 $dir | wc -l) $dir
done | sort -nr | tee ${tree}.dups
