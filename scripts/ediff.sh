#! /bin/ksh

if	[ "${1##/}" = "$1" ]
then	# not absolute, make it so.
	A="$(pwd)/$1"
else	A="$1"
fi

if	[ "${2##/}" = "$2" ]
then	# not absolute, make it so.
	B="$(pwd)/$2"
else	B="$2"
fi

/usr/local/bin/gnudoit "(ediff-files \"$A\" \"$B\")"
echo Mick, check inter-machine capability and replace /usr/local/bin/${0##/*}
