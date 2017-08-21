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
FULLNAME="$(id -F)"
git config --global user.name "$FULLNAME"
MAILADDR="$(domainname)"
if   [[ -z "$MAILADDR" ]]
then MAILADDR="$(uname -n)"
fi
MAILADDR="$(id -u -n)@$MAILADDR"
git config --global user.email "$MAILADDR"
echo "git user name \"$FULLNAME\""
echo "git email \"$MAILADDR\""

if   [[ $(uname -s) = Darwin ]]
then sed -i .original -e '/# OSX Only/s/^\([ 	]*\)#/\1/'  ~/.ssh/config
fi
