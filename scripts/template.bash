#! /bin/bash

# USAGE:
# Usage: eval `PROGRAM [-c] [-s] setup_version`
# 		-OR-
# Usage: eval `PROGRAM [-c] [-s] TOS_SYSTEM COMPILER_VERSION`
# END USAGE

# HELP:

# where SETUP_VERSION is one of the version strings returned if PROGRAM
# is invoked without arguments.

# This program writes shell command to standard out such that if the
# result is evaluated by the shell, the critical environmental variables
# and shell functions needed by both the BUILD script and the build
# environment in general get set properly. For csh-like shells, use an
# alias like  so:
# 		alias setup 'eval `setup_internal -c \!*`'
# For sh-like shells, use a shell function like so:
# 		setup(){ eval `setup_internal "$@"`; }

# When -c is specified, the commands are suitable for csh and
# derivatives.

# When -s is specified, the commands are suitable for sh and
# derivatives. 

# When neither -c nor -s is specified, the environment variable SHELL is
# checked. If is contains the string "csh", then csh syntax is used,
# otherwise sh syntax is used.
 
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
SUFFIX=

# Internal use variables
SYSTEM=
VERSION=

# First, try to determine SHELL type. Use heuristic, if csh appears in
# $SHELL, set csh, else set sh
if	[ "${SHELL##*csh}" = "$SHELL" ]
then	SUFFIX=sh
else	SUFFIX=csh
fi

Usage() {
    echo "$USAGE" 1>&2
    exit ${1-1}
}

Help() {
    echo "$HELP" 1>&2
    exit ${1-1}
}

# process options
while getopts cs opt
do	case $opt in
	c)	SUFFIX=csh ;;
	s)	SUFFIX=sh ;;
	\?)	Help;;
	esac
done
shift $((OPTIND - 1))

# process arguments
case	$# in
0)	list_versions
	exit 0
	;;
1)	VERSION=${1##*/}
	SYSTEM=${1%%/$VERSION}
	;;
2)	VERSION=$2
	SYSTEM=${1%%/}
	;;
*)	Usage 2;;
esac

doOp() {
    if   "$@"
    then echo "Successfully completed '$*'"
    else echo "FAILED: '$*'"
    fi
}
donedir=$HOME/.$prog.done
doDependentOp() {
    # First arg is a list of files that must be older than the done
    # done file
    dependencies=$1
    shift
    donefile=$donedir/.$(echo "$*"|tr " /" "_%")
    for dependency in $dependencies
    do  if [[ $donefile -nt $dependency ]]
        then :               # no need to execute
        else # execute and cut the loop short
             if   "$@"
             then echo "Successfully completed '$*'"
                  touch $donefile
                  return 0
             else echo "FAILED: '$*'"
                  return 1
             fi
        fi
    done
    echo "Not Needed, not executed: '$*'"
}

countlines() {
    # because 'echo "$var"|wc -l' counts zero lines as one
    if   [[ -z "$*" ]]
    then echo 0
    else echo "$*" | wc -l
    fi
}
