#! /bin/bash
# Find No ID Messages

if   (($# == 0))
then set . # make sure "$@" generates at least one argument
fi

prog=${0##*/}
tmp=/tmp/$prog.$$

x=0
fx=0
sx=0
mx=0
sfx=0
mfx=0
msx=0
msfx=0

find "$@" -follow -type f -print |
    while read file				# whole line
    do headers="$(sed -e '/^$/,$d' "$file" | egrep '^(From|Subject|Message-Id): ')"
       from=$(echo "$headers"| egrep '^From: ')
       subject=$(echo "$headers"| egrep '^Subject: ')
       mid=$(echo "$headers"| egrep '^Message-Id: ')
       type=x
       if   [[ -n $from ]]
       then type=f$type
       fi
       if   [[ -n $subject ]]
       then type=s$type
       fi
       if   [[ -n $mid ]]
       then type=m$type
       fi
       case $type in
	x) ((x++));;
	fx) ((fx++));;
	sx) ((sx++));;
	mx) ((mx++));;
	sfx) ((sfx++));;
	mfx) ((mfx++));;
	msx) ((msx++));;
	msfx) ((msfx++));;
       esac
       echo $x $fx $sx $mx $sfx $mfx $msx $msfx >$tmp
    done
read x fx sx mx sfx mfx msx msfx <$tmp
((total = x + fx + sx + mx + sfx + mfx + msx + msfx))

echo $total files processed
echo $((total - x)) are messages
((mid = mx + mfx + msx + msfx ))
echo $mid have mids
echo $x non-message files
echo $fx from only
echo $sx subject only
echo $mx message id only
echo $sfx subject and from only "(messages with no mid)"
echo $mfx message id and from only "(sms?)"
echo $msx message id and subject only
echo $msfx message id, subject and from
