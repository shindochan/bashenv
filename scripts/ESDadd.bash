#! /bin/bash

# USAGE:
# Usage: PROGRAM
# END USAGE

# HELP:

# Uses environment variable ESDTSV to point to a tsv file with headers
# PROGRAM will prompt for each field in file. Certain fields will display
# defaults. If ESDTSV is not set or empty, the default file is
#    ~/Library/Mobile Documents/com~apple~CloudDocs/JobSearch<YYYY>/JobSearch<YYYY>ESD.tsv

# END HELP

prog=${0##*/}
prog=${prog%%_internal}
USAGE=$(sed -e '1,/^# USAGE:$/d' -e '/^# END USAGE$/,$d' -e 's/^# //' \
		-e "s PROGRAM $prog " $0)
HELP="$USAGE
$(sed -e '1,/^# HELP:$/d' -e '/^# END HELP/,$d'	 -e 's/^# //' \
	-e "s PROGRAM $prog " $0)"
# Variables set via command line options

# Internal use variables
if   [[ -z $ESDTSV ]]
then export ESDTSV="$HOME//Library/Mobile Documents/com~apple~CloudDocs/JobSearch$(date +%Y)/JobSearch$(date +%Y)ESD.tsv"
fi

Usage() {
    echo "$USAGE" 1>&2
    exit ${1-1}
}

Help() {
    echo "$HELP" 1>&2
    exit ${1-1}
}

tsvcols ()
{
    head -1 "$1" | tr '\t' '\n' | cat -n
}

if   [[ ! -r "$ESDTSV" ]]
then echo 1>&2  "$prof: File '$ESDTSV' does not exist"
     Help 1
     # not reached
fi

if head -1 "$ESDTSV" | grep -q '\t'
then :
else echo 1>&2 "$prog: '$ESDTSV' is not a TSV file."
     Help 2
     # not reached
fi


# process options
# No options yet...
# while getopts cs opt
# do	case $opt in
# 	c)	SUFFIX=csh ;;
# 	s)	SUFFIX=sh ;;
# 	\?)	Help 3;;
# 	esac
# done
# shift $((OPTIND - 1))

# process arguments
case	$# in
0)	;;
*)	Help 4;;
esac


finish=
while [[ $finish != "q" ]]
do    line=
      for field in $(tsvcols "$ESDTSV" | cut -f2 | tr ' ' _)
      do  case "$field" in
              *Date)    default=$(date +%F) ;;
              Kind)     default=application ;;
              Who*)     default=website ;;
              w/e)      dayofweek=$(date +%u)
                        ((days = 6 - dayofweek))
                        if   ((days < 0))
                        then ((days += 7))
                        fi
                        default=$(date -v +${days}d +%F) ;;
              Status)   default=Open ;;
              *)        default= ;;
          esac

          default=$(echo -n  $default)
          prompt="$field"
          if   [[ -n $default ]]
          then prompt="${prompt}[$default]"
          fi
          read -p "${prompt}: " value
          if   [[  -z $value ]]
          then value="$default"
          fi
          # echo "field = '$field', value = '$value'"

          line="$line$value	"
      done
      # echo "$line" | sed -e 's/.$//' | cat -vet
      echo "$line" | sed -e 's/.$//' >>"$ESDTSV"

    read -p "(q to quit, anything else to add another) " finish
done
exit 0


