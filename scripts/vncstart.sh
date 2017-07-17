#! /bin/bash

myname=${0##*/}


if	[ x"$VNCSCREEN" = x ]
then	echo 1>&2 "$myname: VNCSCREEN must be set and is not"
	exit 1
fi

if	[ x"$VNCGEOMETRY" = x ]
then	echo 1>&2 "$myname: VNCGEOMETRY must be set and is not"
	exit 1
fi

pidfile=$HOME/.vnc/`uname -n`:$VNCSCREEN.pid
startvnc=true
if	[ -f $pidfile ]
then	if	kill -0 `cat $pidfile`
	then	echo 1>&2 $myname: VNC running
	startvnc=
	fi
fi

if	[ x"$startvnc" != x ]
then	# set up .X11 directory for security
	if	[ ! -d /tmp/.X11-unix ]
	then	echo 1>&2 $myname: Creating /tmp/.X11-unix
		mkdir /tmp/.X11-unix
	fi
	echo 1>&2 $myname Making /tmp/.X11-unix sticky
	chmod 01777 /tmp/.X11-unix
	echo 1>&2 "$myname: Starting vnc service on screen '$VNCSCREEN'"
	logfile=$myname.log
	nohup /usr/local/bin/vncserver -geometry $VNCGEOMETRY \
			-name `uname -n` :$VNCSCREEN <&- >$logfile 2>&1&
	wait
	sleep 10
	cat $logfile
fi
VNCDISPLAY=localhost:$VNCSCREEN
vncviewer -owncmap -shared -geometry $VNCGEOMETRY+0-0 $VNCDISPLAY
