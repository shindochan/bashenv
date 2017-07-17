#! /bin/bash

myname=${0##*/}
vncdir=$HOME/.vnc
vncinfo=$vncdir/vncinfo
if	[ -f $vncinfo ]
then	source $vncinfo
fi

pidfile=$vncdir/`uname -n`:$VNCSCREEN.pid

if	[ -f $pidfile ]
then	if	kill -0 `cat $pidfile` >/dev/null 2>/dev/null
	then	# VNC running
		exit 0
	fi
fi

if	[ ! -d $vncdir ]
then	mkdir $vncdir
fi

logfile=$vncdir/$myname.log
if	[ -f $logfile ]
then	mv -f $logfile $logfile.old
fi
exec >$logfile 2>&1

echo "<<<<<< initial environment >>>>>>"
set
echo "<<<<<< end initial environment >>>>>>"

if	[ -f $HOME/.setpath ]
then	source $HOME/.setpath
fi

if	[ x"$VNCSCREEN" = x ]
then	echo 1>&2 "$myname: VNCSCREEN must be set and is not"
	exit 1
fi

if	[ x"$VNCGEOMETRY" = x ]
then	echo 1>&2 "$myname: VNCGEOMETRY must be set and is not"
	exit 1
fi

VNCOPT=":$VNCSCREEN -geometry $VNCGEOMETRY -depth $VNCDEPTH"
if	[ -n "$VNCDPI" ]
then	VNCOPT="$VNCOPT -dpi $VNCDPI"
fi
echo "<<<<<< final environment >>>>>>"
set
echo "<<<<<< end final environment >>>>>>"

vncserver $VNCOPT  -name `uname -n` -nolisten local <&- >$logfile 2>&1&
