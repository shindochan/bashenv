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
