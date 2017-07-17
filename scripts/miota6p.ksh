#! /bin/ksh

FREQ=250M
echo "Frequency fixed at ${FREQ}Hz"

if	[[ "${FREQ%%M}" != "$FREQ" ]]
then	FREQ=$(( 1000000 * ${FREQ%%M} ))
fi
export FREQ

process_kstat_line()
{
	line=$1
	label=${line%%:*}
	rest=${line##$label}
	set $rest
	if	[[ "$1" = "no" ]]
	then	# no samples, nothing to do but relax and go deeper within
		return 1
	fi
	
	return 0
}

process_bufcache()
{
	return 0
}

process_ds()
{
	return 0
}

process_io()
{
	return 0
}

process_ipi()
{
	return 0
}

process_mad()
{
	return 0
}

process_raw()
{
export MBYTES=$2
while	read kstat bytes area rest
do	case	$kstat in
	kstat)	if	[[ $bytes = area ]]
		then	# this is an area designation
			case $area in
			kern_stat_bufcache)	process_bufcache
						;;
			kern_stat_ds)		process_ds
						;;
			kern_stat_io)		process_io
						;;
			kern_stat_ipi)		process_ipi
						;;
			kern_stat_mad)		process_mad
						;;
			esac
		fi
		;;
	kstat:)	# no action
		;;
	    *)	return
		;;
	esac
done
}

process_iota()
{
while	read line
do	case	$line in
	===*)	break
		;;
	esac
done
# Must somehow set MBYTES
read filen min avg max sd
min=$(echo "9k$min 1000000* 1024/1024/p"|dc)
avg=$(echo "9k$avg 1000000* 1024/1024/p"|dc)
max=$(echo "9k$max 1000000* 1024/1024/p"|dc)
echo "iota $1 min $min ave $avg max $max sd $sd"
process_raw $1 $2
}

process_file()
{
	read line	# file prefix
	read line	# "Testing raw I/O" line
	if	[[ $line != "Testing raw I/O" ]]
	then	echo 1>&2 "${0##*/}: File is not a miota6 log"
		exit 1
	fi
	process_raw 'read 2MB x 1 raw' 2
	process_raw 'read 2MB x 2 raw' 2
	process_raw 'read 128MB x 1 raw' 128
	process_iota '* write 4MB x 20' 76.293945312
	process_iota 'write 120 MB x 5 A' 114.440917968
	process_iota 'write 120 MB x 5 B' 114.440917968
	process_iota 'write 30 MB x 20 A' 114.440917968
	process_iota 'write 30 MB x 20 B' 114.440917968
	process_iota 'read 120MB x 5 A' 114.440917968
	process_iota 'read 120MB x 5 B' 114.440917968
	process_iota 'read 30MB x 20 A' 114.440917968
	process_iota 'read 30MB x 20 B' 114.440917968
	process_iota '* read 4MB x 20 A' 76.293945312
	process_iota '* read 4MB x 20 B' 76.293945312
	process_iota '* read 4MB x 20 C' 76.293945312
	process_iota '* read 4MB x 20 D' 76.293945312
	process_iota '* rewrite 4MB x 20' 76.293945312
	process_iota '* read 4MB x 20 E' 76.293945312
	process_iota '* read 4MB x 20 F' 76.293945312
	process_iota '* read 4MB x 20 G' 76.293945312
	process_iota '* read 4MB x 20 H' 76.293945312
}

for	i in "$@"
do	if	[ -r "$i" ]
	then	echo File $i
		sed -e '/^kstat .*:$/N' \
		    -e '/^kstat .*:\n	avg/s/\n//' $i | process_file
	else	echo 1>&2 "${0##*/}: cannot read file '$i', continuing"
	fi
done
