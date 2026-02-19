#! /bin/bash
desktopdir=${0%/*}
cd $desktopdir # all files in originals must match the corresponding
# file in $HOME, otherwise the install will not be done.
if   [[ -d originals ]]
then nomatch=$(cd originals
      find . -type f -print |
          while read i
          do diff -q $i ~/$i 2>&1
          done)
     if [[ -n $nomatch ]]
        then echo 1>&2 ${0##*/}: Unintegrated changes, install not done.
             echo 1>&2 ${0##*/}: Remove or update files in
             echo 1>&2 ${0##*/}: $desktopdir/originals to fix
             echo 1>&2 ${0##*/}: file list:
             echo "$nomatch"| tr ';' ',' |
                 sed -e "s;^;${0##*/}:	;" 1>&2
             exit 1
     fi
fi

if   [[ ! -f Manifest ]]
then echo 1>&2 ${0##*/}: Missing $desktopdir/Manifest, nothing installed
     exit 1
fi

tar cf - $(cat Manifest) | (cd ~; tar xf -)


if   [[ $(uname -s) = Darwin ]]
then sed -i .original -e '/# OSX Only/s/^\([ 	]*\)#/\1/'  ~/.ssh/config
     echo "Enabling locate db, requires login password"
     sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist
fi

ghc ()
{
    GITHUB=${GITHUB:=$HOME/.src/github}
    group=$1 project=$2;
    SRC=$GITHUB/$group
    if [[ ! -d $SRC ]]; then
        mkdir -p $SRC;
    fi;
    ( cd $SRC
      git clone git@github.com:$group/$project.git )
}

export GITHOMEBREW=$GITHUB/homebrew
ghc homebrew install
$GITHOMEBREW/install/install.sh
brew install cask clamav

cat <<\EOF
cp clamd.conf.sample clamd.conf
ed clamd.conf <<xyz
85c
DatabaseDirectory /var/lib/clamav
.
7,8d
w
q
xyz
cp freshclam.conf.sample freshclam.conf
ed fleshclam.conf <<xyz
13c
DatabaseDirectory /var/lib/clamav
.
7,8d
w
q
xyz

mkdir /var/lib/clamav
chown appropriately

freshclam
Clamscan ~/.src/github/homebrew/install
Also scan iterm

git config --global user.name "Full X. Name"
git config --global user.email "user@domain.tld"


brew tap railwaycat/emacsmacport
brew install emacs-mac --no-quarantine
install 1Password
scan ~/.src/github/homebrew/install
install bettertouchtool
Install Logitech Gaming Software
install emacs
install iterm2: https://iterm2.com

finderShowHiddenFiles

Need to collect changes from Notes
Need to look at .bashrc for the homebrew changes: need append path functions for manpath and infopath!!
Need to understand what this construct does: export PATH="/usr/local/bin:/usr/local/sbin${PATH+:$PATH}";
Need to push git changes.

EOF
