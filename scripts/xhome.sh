#! /bin/sh
trap 'eval `ssh-agent -k`' 0
echo remember to collect geometries!
eval `ssh-agent`
ssh-add
emacs -f rmail -geometry 80x52-0+25&
xterm -geometry 80x24+0+309&
xterm -geometry 80x24+0-28&
netscape&
from|wc -l
from | more
