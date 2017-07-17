#! /usr/local/bin/bash
(set -x
	(cd ~/sys;gmake config clean)
	(cd ~/system/tos/usr/src/util/usr.sbin/config;gmake clean install)
	(cd teratest;gmake depend_all all) 
	(cd suntest;gmake depend_all all)
) 2>&1 | mailx -s "Local build of $(date)" $LOGNAME

