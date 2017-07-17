#! /bin/sh
# this script runs until there are no jobs for the user in the imagen queue
# user=`/usr/lbin/id -u` # this should already be set up.
# the following line is because lpr is SO SLOW.
sleep 5
while lpstat -o $PRINTER $*|grep "[^a-zA-Z]$LOGNAME[^a-zA-Z]" >/dev/null
do sleep 5
done
