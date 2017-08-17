#! /bin/bash
BASHRC_SUFFIXES="aliases variables functions rc"
LOGFILE=~/.bashrc.log
_log()
{
    echo ".bashrc($$)@$(date +%FT%T.%N): $*" >>$LOGFILE
}
_log
_log entry

if   [[ -z "$LoggedIn" ]]
then _log LoggedIn Not set, running .bash_profile
     source ~/.bash_profile
     _log Done sourcing ~/.bash_profile
     return
fi

# NOTE: must be idempotent below this point.
for suffix in $BASHRC_SUFFIXES
do file=~/.bash_$suffix
   if [[ -f $file ]]
   then _log loading "'$file'"
	source $file
   fi
done

if [[ -n $BASHRC_PREFIXES ]]
then for prefix in $BASHRC_PREFIXES
     do for suffix in $BASHRC_SUFFIXES
        do file=$prefix$suffix
	   if [[ -f $file ]]
	   then _log loading "'$file'"
	        source $file
	   fi
        done
     done
fi

# If not running interactively, don't do anything, Useful example, not
# sure this is the right thing to do, so commented out.
case $- in
    *i*) _log is interactive;;
      *) # return;;
         _log is NOT interactive;;
esac

shopt -s checkwinsize # Update LINES and COLUMNS after each command
#shopt -s globstar # ** matches across dir levels
shopt -s histappend

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# make less more friendly for non-text input files, see lesspipe(1) and lessfile(1)
# Choose one--pipe is faster to start but can't display percentages
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
# [ -x /usr/bin/lessfile ] && eval "$(SHELL=/bin/sh lessfile)"

PS1='\u@\h:\w\$ '

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac
_log "PS1='$PS1'"
_log Done
_log
