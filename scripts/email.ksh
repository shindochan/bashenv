#! /bin/ksh

FROM=${USER=${LOGNAME=$(logname)}}@$(uname -n).$(domainname)
MAILBOX=$1
HOST=${MAILBOX##*@}
shift

send(){
	print -  "$@"
	print -p "$@"
}

# set up tmp files and their removal
tmp=/tmp/email$$
trap "rm -f ${tmp}*" 0 1 2 3	# remove tmp file on hangup or quit or exit
UMASK=$(umask)
umask 077
cat <<END >${tmp}A
Envelope-From: $FROM
Envelope-To: $MAILBOX
From: $FROM
To: $MAILBOX

****** REPLACE THIS LINE WITH YOUR MESSAGE ******
END
/bin/chmod +w ${tmp}A
umask $UMASK

# get message
${EDITOR=emacs} ${tmp}A

while	read cmd?"Command (Edit, Mail, Print, Quit)? "
do	case	$cmd in
	E*|e*)
		${EDITOR=emacs} ${tmp}A
		;;
	M*|m*)
		break;
		;;
	P*|p*)
		${PAGER=more} ${tmp}A
		;;
	Q*|q*)
		exit
		;;
	esac
done

ENVELOPE_FROM=$(sed -e '/Envelope-From:[ 	]*/!d' \
		    -e 's/Envelope-From:[ 	]*//' <${tmp}A)
ENVELOPE_TO=$(sed -e '/Envelope-To:[ 	]*/!d' \
		    -e 's/Envelope-To:[	 ]*//' <${tmp}A)
HOST=${ENVELOPE_TO##*@}
echo Envelope host is '"'"$HOST"'"'
if	[[ $HOST = $ENVELOPE_TO ]]
then	HOST=localhost
else	HOST=$(nslookup -querytype=MX $HOST | \
		sed -e '/mail exchanger/!d' -e 's/^.*preference = //'| \
		sort -n | \
		sed -e '1!d' -e 's/^.* //' -e 's/\.$//')
	echo nslookup gives MX host as '"'"$HOST"'"'
fi

/usr/bin/telnet ${HOST:-localhost} 25 |&

while read -p code rest
do
	print -r $code $rest
	case $code in
	220)	# got greeting
		send helo $(hostname).$(domainname)
		STATE=HELO
		;;
	221)	# Got goodbye
		exit
		;;
	250|251) # Got response to $STATE
		case $STATE in
		HELO)	send "MAIL FROM: <$ENVELOPE_FROM>"
			STATE=MAIL
			;;
		MAIL)	send "RCPT TO: <$ENVELOPE_TO>"
			STATE=RCPT
			;;
		RCPT)	send DATA
			STATE=DATA
			;;
		DATA)	send QUIT
			;;
		esac
		;;
	354)	# Time to enter mail and do hidden dot.
		sed <${tmp}A -e '/Envelope-From:[ 	]*/d' \
			     -e '/Envelope-To:[	 ]*/d' |
			while read line
			do	case "$line" in
				.*)	send ".$line"
					;;
				*)	send "$line"
					;;
				esac
			done
			send .
			;;
	4??|5??) # Error
		send QUIT
		exit 1
		;;
	esac
done
