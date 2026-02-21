#! /bin/bash

GITBASHENV=$HOME/.src/github/shindochan
cd
if   type -t xcode-select >/dev/null
then # install xcode command line tools to get git
    echo installing Xcode command line tools
    xcode-select --install
fi
tar xvf ${0%/*}/ssh.tgz
# Bootstrap the environment. Get bashenv from github and install it.
# There are still manual steps.

# go to home
mkdir -p $GITBASHENV
cd $GITBASHENV
git clone git@github.com:shindochan/bashenv.git
cd
$GITBASHENV/bashenv/desktop/install-env.bash

