#! /bin/bash

# USAGE:
# Usage: PROGRAM -t <table column> -c <column column> -f <foreign key column ><tsv file>
# END USAGE

# HELP:

# where column numbers start at 1. Default columns:
# table name  2
# column name 3
# foreign key 4
# column type 6
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
TABLE=2
COLUMN=3
FOREIGN_KEY=4
TYPE=6


# Internal use variables

Usage() {
    echo "$USAGE" 1>&2
    exit ${1-1}
}

Help() {
    echo "$HELP" 1>&2
    exit ${1-1}
}

# process options
while getopts cftT opt
do	case $opt in
        T) TABLE=$OPTARG;;
        c) COLUMN=$OPTARG;;
        f) FOREIGN_KEY=$OPTARG;;
        t) TYPE=$OPTARG;;
	\?)	Help;;
	esac
done
shift $((OPTIND - 1))

# process arguments
case	$# in
    0)	unset INFILE;;
    1)	INFILE="$1";;
    *)	Usage 2;;
esac


countlines() {
    # because 'echo "$var"|wc -l' counts zero lines as one
    if   [[ -z "$*" ]]
    then echo 0
    else echo "$*" | wc -l
    fi
}

# schemaAlpha.tsv |cut -f 2

echo "TABLE='$TABLE'" 1>&2
echo "COLUMN='$COLUMN'" 1>&2
echo "FOREIGN_KEY='$FOREIGN_KEY'" 1>&2
echo "TYPE='$TYPE'" 1>&2
echo "INFILE='$INFILE'" 1>&2

cut -f $TABLE "$INFILE" |
    sed -e '1d' -e 's,^[^/]*/,,' -e '/^$/d' | sort -u |
    while read table
    do realtable=$(echo $table|tr ' ' _)
       echo "DROP TABLE IF EXISTS $realtable CASCADE;"
       echo "CREATE TABLE $realtable ("
       COMMA=
       cut -f "$TABLE","$COLUMN" "$INFILE" |
       sed -e "/^[^	]*$table	/"'!d' -e 's///' -e 's,^[^/]*/,,'  |
           sort -u |
           while read column
           do rcolumn=$(echo "$column" | tr " " _)
              type=$(cut -f $TABLE,$COLUMN,$TYPE "$INFILE" |
                         sed -e "/^[^	]*$table	[^	]*$column	/"'!d' -e 's///' |
                         head -1)
              # specify foreign keys
              fkey=$(sed -e "/$table/!d" -e "/$column/!d" $INFILE | cut -f $FOREIGN_KEY |
                          sed -e 's,^[^/]*/,,'  | fgrep "$rcolumn")
              if   [[ -n $fkey ]]
              then fkey="FOREIGN KEY"
              else fkey=""
              fi
              fkey=""
              pkey=$(sed -e '/^PrimaryKey/!d' -e "/[/	]$table	/!d" \
                         -e "/[/	]$column	/!d" $INFILE)
              if   [[ -n $pkey ]]
              then # type overriden by primary key line
                   type=$(echo "$pkey" | cut -f $TYPE)
                  pkey="PRIMARY KEY"
              else pkey=""
              fi
               echo "  $COMMA $rcolumn $type $fkey $pkey"
               COMMA=,
           done
       echo ');'
       echo
    done

