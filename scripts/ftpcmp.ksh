#! /bin/ksh

if	[ $# -ne 3 ]
then	echo 1>&2 Usage: ${0##*/} file host user
	exit 1
fi

count=0


DEBUG=
file=$1
host=$2
user=$3
sentinel=${file}.rm-to-stop
echo $file >$sentinel

send()
{
	[[ -n $DEBUG ]] && print - "$@"
	print -p "$@"
}

ftp_open()
{
	ftp -n -v $host |&
	FTPPID=$!
	while	read -p code rest
	do
		[[ -n $DEBUG ]] && print -r $code $rest
		case	$code in
		220|530)	# Need password!
			stty -echo
			IFS= read -r line?"Password: "
			stty echo
			echo
			print -p "user $user \"$line\""
			line=012345678
			;;
		230)	return
			;;
		esac
	done
}

ftp_get()
{
	ONCE=
	send "bin"
	while	read -p code rest
	do
		[[ -n $DEBUG ]] && print -r $code $rest
		case	$code in
		200)	# 1st time, send command
			if	[[ -z "$ONCE" ]]
			then	send "get $1 $2"
				ONCE=true
			fi
			;;
		226)	# done
			return
			;;
		esac
	done
}

ftp_put()
{
	ONCE=
	send "bin"
	while	read -p code rest
	do
		[[ -n $DEBUG ]] && print -r $code $rest
		case	$code in
		200)	# 1st time, send command
			if	[[ -z "$ONCE" ]]
			then	send "put $1 $2"
				ONCE=true
			fi
			;;
		226)	# done
			return
			;;
		esac
	done
}

ftp_delete()
{
	send "delete $1"
	while	read -p code rest
	do
		[[ -n $DEBUG ]] && print -r $code $rest
		case	$code in
		250)	# done
			return
			;;
		esac
	done
}

ftp_close()
{
	print -p quit
	while	read -p line
	do
		[[ -n $DEBUG ]] && print -r $line
	done
}

cleanup()
{
	ftp_delete $FTPFILE
	ftp_close
	rm -f ${LOCALPREFIX}.*
}

ftp_open $host
FTPFILE=$file.$(uname -n).$$
LOCALPREFIX=$file.$$
((i = 0))

while	[[ -f $sentinel ]]
do
	copy=$LOCALPREFIX.$i
	ftp_put $file $FTPFILE
	ftp_get $FTPFILE $copy

	if	cmp $file $copy
	then	if	((i > 0))
		then	rm $LOCALPREFIX.$((i - 1))
		fi
	else	echo 1>&2 $file and $copy differ
		cleanup
		exit 2
	fi
	if	[[ ! -f $sentinel ]]
	then	echo ${0##*/}: exiting normally after $i iterations
		cleanup
		exit 0
	fi
	((i = i + 1))
	if	((i % 10 == 0))
	then	echo ${0##*/}: $i ftp/cmp pairs completed successfully
	fi
done
