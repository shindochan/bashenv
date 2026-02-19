#! /bin/bash

GITBASHENV=$HOME/.src/github/shindochan
# Bootstrap the environment. Get bashenv from github and install it.
# There are still manual steps.

# go to home
cd
mkdir -p $GITBASHENV
cd $GITBASHENV
if   type -t xcode-select >/dev/null
then # install xcode command line tools to get git
    echo installing Xcode command line tools
    xcode-select --install
fi
git clone https://github.com/shindochan/bashenv.git
cd
$GITBASHENV/bashenv/desktop/install-env.bash

