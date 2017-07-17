#! /bin/sh
echo "$0 SHLVL = '$SHLVL'"
SHLVL=0
export SHLVL

if	whence whence 2>/dev/null
then	alias which=whence
fi

[ -x /usr/local/bin/bash ] && exec /usr/local/bin/bash --login
[ -x "$(which bash 2>/dev/null)" ] && exec bash --login
echo BASH not available, using ksh
[ -x /bin/ksh ] && exec egg /bin/ksh -ksh
[ -x /usr/bin/ksh ] && exec egg /usr/bin/ksh -ksh
[ -x "$(which ksh 2>/dev/null)" ] && exec egg ksh -ksh
[ -x /usr/local/bin/tcsh ] && exec /usr/local/bin/tcsh
[ -x /bin/sh ] && exec egg /bin/sh -sh
echo No shells found!
sleep 5
exit
