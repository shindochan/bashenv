#! /bin/bash
BASHRC_SUFFIXES="aliases variables functions rc"
_log()
{
   LOGFILE=~/.bash.log
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
_log "LoggedIn='$LoggedIn'"

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

# User specific environment and startup programs
appendPath /usr/local/bin /sbin /usr/sbin
[[ -n $BINDIR ]] && prependPath $BINDIR
_log final PATH="'$PATH'"
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

appendExistingPath $GCLOUD_SDK/bin
if   [[ -f $GCLOUD_SDK/completion.bash.inc ]]
then source $GCLOUD_SDK/completion.bash.inc
fi

appendExistingPath "$HOME/.cargo/bin"


# make less more friendly for non-text input files, see lesspipe(1) and lessfile(1)
# Choose one--pipe is faster to start but can't display percentages
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
# [ -x /usr/bin/lessfile ] && eval "$(SHELL=/bin/sh lessfile)"

export PS1='\u@\h:\w\$ '

_log "first set PS1='$PS1'"

if   [[ -f /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-completion.bash ]]
then source /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-completion.bash
elif [[ -f /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash ]]
then echo "Install XCode. Using CommandLineTools for git-completion.bash"
     source /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
elif [[ $(uname -s) == "Darwin" ]]
then echo "git-completion.bash not found, install XCode."
fi

if   [[ -f /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh ]]
then source /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh
elif [[ -f /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh ]]
then echo "Pleease Install XCode, using CommandLineTOolsfor git-prompt.sh"
     source /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
elif [[ $(uname -s) == "Darwin" ]]
then echo "git-prompt.sh not found, please install XCodee."
fi

export GIT_PS1_SHOWDIRTYSTATE=true
export PS1="${PS1%%\\\$ }"'$(__git_ps1 " (%s)")\$ '
_log "add git to PS1=$PS1"
# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
   export PS1="\[\e]0;${PS1%%\\\$ }\a\]$PS1"
   ;;
*)
   ;;
esac

_log "final PS1='$PS1'"
_log Done
_log
