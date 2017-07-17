#!/bin/sh
#
# $Header: /home/users/ericc/bin/RCS/vnc,v 1.29 2001/03/01 21:07:14 ericc Exp ericc $
#
# Getting the Appropriate Virtual Desktop to Monitor an MTA
# =========================================================
# This script spawns a vncviewer connected to the Merrill Place
# vncserver designated to monitor the specified MTA system.
#
Usage="`basename $0` [options] mta_system

  options:
    -b          8-bit pixels, ie. \"vncviewer -bgr233 ...\" (default)
    -B          do not use \"vncviewer -bgr233 ...\"
    -c          private colormap, ie. \"vncviewer -owncmap ...\"
    -H          enumerate recognized mta_systems
    -t title    specify vncviewer title bar (%s = default title)
    -T          TrueColor visual, ie. \"vncviewer -truecolour ...\"
    -w          enable mouse and keyboard input (not the default)
"
#
# This script can only be used on Solaris hosts at Merrill Place.  If
# your desktop is a SunOS workstation, rlogin to a Solaris host, set
# your $DISPLAY to point at your desktop, then invoke this script.
#
#
# Mapping of MTA names to vncserver X-displays
# --------------------------------------------
# To add or change an MTA system to this script, merely edit the table,
# $Assignments below.  Hyphens and underscores are equivalent, and case
# is ignored.  Comments begin with '#'; blank lines are ignored.
#
#	  VNC server host:port		MTA System
#	  ....................		..........
Assignments="
		test-sbtv1.wc.cray.com:5907		boomer
		test-sbtv1.wc.cray.com:5908		boomer-ecs
		test-sbtv1.wc.cray.com:5907		sbtv1
		test-sbtv1.wc.cray.com:5908		sbtv1-ecs
		chinook-mw:5907		chinook
		chinook-mw:5908		chinook-ecs
		enri-mw:5907		enri
		enri-mw:5908		enri-ecs
		hugin-mw:5907		hugin
		hugin-mw:5908		hugin-ecs
		test-net2:5907		test-net2
		test-net2:5908		test-net2-ecs
		test-ppart1:5907	test-ppart1
		test-sbtv2:5907		sbtv2
		test-sbtv2:5908		sbtv2-ecs
		test-sbtv3:5907		sbtv3
		test-sbtv3:5908		sbtv3-ecs
		zeppelin-mw:5907	zepellin
		zeppelin-mw:5907	zeppelin
		zeppelin-mw:5908	zeppelin-ecs
#
# Merrill Place maintenance workstations will host their own VNCs
# eventually.
#
		vnc:5904		walla
		vnc:5906		test-rm1
		vnc:5909		test-rm2
#
# VNC-within-a-VNC to reduce TCP/IP traffic to/from remote MTA sites;
# the next remote site should map locally to vnc:5927, vnc:5937, ...
#
		vnc:5917		sdsc
		vnc:5917		sdsc-console
		vnc:5918		sdsc-ecs
"
# Append $HOME/.vnchosts, if it exists.
[ -f $HOME/.vnchosts ] && Assignments="$Assignments `cat $HOME/.vnchosts`"

#
# Functions
# =========
# Help()  --  print a usage message on stderr.
#
Help()
{
	cat >&2 <<END
Usage: $Usage
END
}


#
# List()  --  print the MTA system names recognized by this script.
#
# This is done by simply cat'ing the table, $Assignments, ignoring
# comments and blank lines.
#
List()
{
	cat <<END | sed -e "/^#/d" -e "/^ *$/d" |
$Assignments
END
	while read xdisplay system junk
	do
		echo "	$system"
	done |

	sort
}


#
# Map(mta_system_name)  --  echo. on stdout, the Merrill Place
#	vncserver designated to monitor the specified MTA system.
#
# This function is case-insensitive, and regards an underscore (_) as
# equivalent to a hyphen (-).
#
Map()
{
	mta=`echo $1 | tr '[A-Z]_' '[a-z]\-'`	# lower-case and hyphenate

	cat <<END | sed -e "/^#/d" -e "/^ *$/d" |
$Assignments
END
	while read xdisplay system junk
	do
		system=`echo $system | tr '[A-Z]_' '[a-z]\-'`

		if [ "$mta" = "$system" ]
		then
			echo "$xdisplay"
			return
		fi
	done
}


#
# Default Initializations
# =======================
#
BgrOpt=						# "b" for "-bgr233", "B" for no
Cmd=`basename $0`
Options="-depth 8 -shared"
TrueColour=					# TRUE for "-truecolor"
Writable=					# TRUE for no "-viewonly"


#
#
# Main Program
# ============
# Parse the command line
# ----------------------
#
while getopts bBcHt:Tw optletter
do
	case $optletter in
	  b|B)	BgrOpt=$optletter
		;;

	  c)	Options="$Options -owncmap"
		;;

	  H)	List
		exit 1
		;;

	  t)	Options="$Options -xrm \"Vncviewer.title:${OPTARG}\""
		;;

	  T)	Options="$Options -truecolour"
		TrueColour=TRUE
		;;

	  w)	Writable=TRUE
		;;

	  \?)	Help
		exit 13
		;;
	esac
done

shift `expr $OPTIND - 1`


#
# Which MTA system is to be monitored ?
#
xserver=

case $# in
   0)	;;

   *)	xserver=`Map $1`

	[ -z "$xserver" ] &&
		echo "$Cmd: \"$1\" is not the name of an MTA system" >&2
	;;
esac


#
# Is there an X-display to render on ?
# ------------------------------------
#
case "$DISPLAY" in
  "")	echo "$Cmd: set \$DISPLAY in your environment first"
	exit 18
	;;
esac


#
# Massage the vncviewer options so that they are coherent
# -------------------------------------------------------
# Avoid "vncviewer -truecolour -bgr233", which results in a black
# screen.
#
if [ -z "$TrueColour" ]
then
	case "$BgrOpt" in
	"B")	;;

	*)	Options="$Options -bgr233"	# default is "-bgr233"
		;;
	esac

elif [ "$BgrOpt" = "b" ]
then
	echo "$Cmd: \"-b\" and \"-T\" are incompatible"
	exit 19
fi


#
# Is viewonly access sufficient ?
#
if [ -z "$Writable" ]
then
	Options="$Options -viewonly"
fi


echo /usr/local/bin/vncviewer-3.3.3 $Options $xserver >&2
eval /usr/local/bin/vncviewer-3.3.3 $Options $xserver
