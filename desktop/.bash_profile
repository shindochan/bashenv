#! /bin/bash
_logp()
{
   LOGFILE=~/.bash.log
   echo ".bash_profile($$)@$(date +%FT%T.%N): $*" >>$LOGFILE
}

_logp
_logp entry

if   [[ -z "$LoggedIn" ]]
then export LoggedIn=$(date +%FT%T.%N).$$
    _logp LoggedIn set to "'$LoggedIn'"
fi

if	[ -z "$BASH_ENV" ]
then	export BASH_ENV=~/.bashrc
	_logp set "BASH_ENV='$BASH_ENV'"
fi

if   [[ -f "$BASH_ENV" ]]
then _logp sourcing "'$BASH_ENV'"
    source "$BASH_ENV"
    _logp sourced "'$BASH_ENV'"
fi
q
_logp "TMPDIR='$TMPDIR' LOGDIR='$LOGDIR' BINDIR='$BINDIR' SRCDIR='$SRCDIR'"

populate_bindir()
{
   if [[ -n $SRCDIR && \
               -d $SRCDIR/scripts ]]
   then _logp Populating "'$BINDIR'" from "'$SRCDIR'/scripts"
	 (cd $SRCDIR/scripts;/bin/ls -1) |
	     (cd $BINDIR; while read file
			  do ln -s $SRCDIR/scripts/$file ${file%.*}
			  done
	     )
   fi
}

for dir in $LOGDIR $TMPDIR $BINDIR
do  if [[ -n $dir && ! -d $dir ]]
   then _logp making directory "'$dir'"
        mkdir $dir
        case $dir in
            $BINDIR)   populate_bindir;;
        esac
   fi
done

if [[ -n $BASHRC_PREFIXES ]]
then for PREFIX in $BASHRC_PREFIXES
    do file=${PREFIX}profile
	if [[ -f $file ]]
	then _logp loading "'$file'"
	     source $file
	fi
    done
fi

_logp Done
_logp
