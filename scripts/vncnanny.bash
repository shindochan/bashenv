#! /bin/bash

myname=${0##*/}
if	(($# != 1))
then	echo 1>&2 "Usage: $myname <screen-id>"
	exit 1
fi

vncdir=$HOME/.vnc
VNCSCREEN=$1
screen=`uname -n`:$VNCSCREEN
vncinfo=$vncdir/$screen.info

if	[ x"$VNCSCREEN" = x ]
then	echo 1>&2 "$myname: VNCSCREEN must be set and is not"
	exit 1
fi

if	[ -f $vncinfo ]
then	source $vncinfo
fi

stopfile=$vncdir/$screen.stop
if	[ -f $stopfile ]
then	# echo 1>&2 "Exiting because $stopfile exists"
	exit 3
fi

nannyfile=$vncdir/$screen.nanny
if	[ -f $nannyfile ]
then	if	kill -0 `cat $nannyfile` >/dev/null 2>/dev/null
	then	# nanny running
		# echo 1>&2 "Exiting because other nanny exists"
		exit 4
	fi
fi

# no other nanny, we are it
echo $$ >$nannyfile

pidfile=$vncdir/$screen.pid

if	[ -f $pidfile ]
then	while	kill -0 `cat $pidfile` >/dev/null 2>/dev/null
	do	# VNC running, but not ours. Watch it, and stop it if needed
		if	[ -f $stopfile ]
		then	vncserver -kill :$VNCSCREEN
			echo 1>&2 "Stopping because $stopfile exists"
			exit 5
		fi
		# reread $vncinfo before and after sleep.
		[ -f $vncinfo ] && source $vncinfo
		sleep ${VNCSLEEP:-60}
		[ -f $vncinfo ] && source $vncinfo
	done
fi

# When we get to here, we are the nanny, and the vncserver will be our child.
if	[ ! -d $vncdir ]
then	mkdir $vncdir
fi

logfile=$vncdir/$screen.log
if	[ -f $logfile ]
then	mv -f $logfile $logfile.old
fi
exec <&- >$logfile 2>&1

echo "<<<<<< initial environment >>>>>>"
set
echo "<<<<<< end initial environment >>>>>>"

if	[ -f $HOME/.setpath ]
then	source $HOME/.setpath
fi

VNCOPT=":$VNCSCREEN"
if	[ -n "$VNCGEOMETRY" ]
then	VNCOPT="$VNCOPT -geometry $VNCGEOMETRY"
fi
if	[ -n "$VNCDEPTH" ]
then	VNCOPT="$VNCOPT -depth $VNCDEPTH"
fi
if	[ -n "$VNCDPI" ]
then	VNCOPT="$VNCOPT -dpi $VNCDPI"
fi
echo "<<<<<< final environment >>>>>>"
set
echo "<<<<<< end final environment >>>>>>"

echo Using vncserver  ${VNCSERVER:=vncserver}

while	[ ! -f $stopfile ]
do	$VNCSERVER $VNCOPT  -name "$screen" -nolisten local 
done
