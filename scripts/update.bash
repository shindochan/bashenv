#! /bin/bash
# This program, in a CVS tree, will do a test checkout and generate file
# lists of the various sorts like C.check.<date> M.check.<date>, etc.
# 
# Needs the same args used at original checkout

NAME=${0##*/}
FULLYEAR=$(date)
FULLYEAR=${FULLYEAR##* }
OUT=$NAME.$FULLYEAR$(date +%m%d%H%M)

# Check that at least one arg given
if	(($# < 1))
then	echo 1>&2 "Usage: $NAME cvs-checkout-arg+"
	exit 1
fi

if	[ ! -d CVS ] && [ ! -d install/CVS ] && [ ! -d usr/CVS ] && \
	[ ! -d modules/CVS ]
then	echo 1>&2 $NAME: Current directory $(pwd) not a CVS view
	exit 2
fi

rm -f ?.${OUT}*
trap "rm -f ?.${OUT}*" 1 2 3 15
FILES=
S="$NAME: (THIS IS A >>>TEST<<< CHECKOUT ONLY - NO FILES ARE MODIFIED)"
echo  1>&2 "$S"
cvs -n checkout "$@" | grep "^[^?]"  | while	read status file rest
do	FILE=$status.$OUT.pre
	if	[ "${FILES%%${status}*}" == "$FILES" ]
	then	FILES="$FILE $FILES"
	fi
	echo "$file" >>$FILE
done	

for	file in $FILES
do	tar cvf ${file}.tar $(cat $file)
done

FILES=
S="$NAME: (This is the >>>REAL<<< checkout)"
echo  1>&2 "$S"
cvs checkout "$@" | grep "^[^?]"  | while read status file rest
do	echo "$file" >>$status.$OUT
done	

if      [ -f C.$OUT ]
then

        edits=
        for     file in $(cat C.$OUT)
        do      saved=${file%/*}
                [ -z "$saved" ] && saved=.
                saved="$saved/.#${file##*/}"
                saved=$(/bin/ls -1t ${saved}*| head -1)
                if      [ -f "$saved" ]
                then    mv $saved ${file}.local
                        edits="$edits $file"
                fi
        done

        # Now, just call editor on 'em all . . .
	bg=
	[ -n "$EDITOR" ] && editor=$EDITOR
	[ -n "$VISUAL" ] && editor=$VISUAL


	if	[ "${editor##*/}" = emacs ]
	then	if	gnudoit '()' > /dev/null 2>&1
		then	# use gnuclient
			editor=gnuclient
		else	# If DISPLAY is set, do them in the back ground
			[ -n "$DISPLAY" ] && bg=true
		fi
	fi
	if	[ "${editor##*/}" = gnuclient ]
	then	if	gnudoit '()' > /dev/null 2>&1
		then	# use gluclient in the background
			bg=true
		else	# pretend we don't have an editor and fall through
			editor=
		fi
	fi
        if      [ -n "$editor" ]
        then    # use the editor
                for     file in $edits
                do	if	[ -n "$bg" ]
			then	$editor $(pwd)/$file &
			else	$editor $(pwd)/$file
			fi
                done
        else    # No usable editor email the results
                mail="#! /bin/sh;cd `pwd`"
                for     file in $edits
                do      mail="$mail;"'${VISUAL=${EDITOR=/bin/ed}} $file'
                done
                mail=`echo $mail| tr ';' '\012'`
                # NOTE, bash <<- broken, indent 
                # 2nd and 3rd following line when fixed 
                /usr/ucb/mail $USER <<-EOF
$mail
EOF
        fi
fi
