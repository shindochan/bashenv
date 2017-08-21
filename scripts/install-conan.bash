#! /bin/bash
me=${0##*/}
PYTHON_VERSION=$(python -V 2>&1)
if   [[ "$PYTHON_VERSION" != ${PYTHON_VERSION##Python 2.7} ]]
then : # version ok
elif [[ "$PYTHON_VERSION" != ${PYTHON_VERSION##Python 3.} ]]
then : # version ok
else echo 1>&2 "$me: Must have python 2.7 or 3.X to install conan"
     exit 1
fi

if   type -P pip >/dev/null
then :                          # pip already installed
else if   type -P easy_install >/dev/null
     then :                     # easy_install available
     else echo 1>&2 "$me: Must have easy_install installed."
          exit 1
     fi
     sudo easy_install pip
fi
sudo pip install virtualenv
(cd ~;virtualenv conan)
source ~/conan/bin/activate
pip install conan
if   [[ -z $BINDIR ]]
then if   [[ -d $HOME/.bin ]]
     then BINDIR=$HOME/.bin
     elif [[ -d $HOME/bin ]]
     then BINDIR=$HOME/bin
     fi
fi
if   [[ -n $BINDIR ]]
then ln -s ~/conan/bin/conan $BINDIR
fi

echo "Now do 'conan remote add <nickname> <repo url>'"
