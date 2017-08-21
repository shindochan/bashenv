#! /bin/bash
me=${0##*/}
if   type -P python >/dev/null 2>&1
then :                          # Python present
else echo 1>&2 "$me: must have python installed"
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
sudo pip install jedi flake8 importmagic autopep8
emacs \
    --batch \
    --eval \
      "(progn \
        (require 'package) \
        (package-initialize) \
        (add-to-list 'package-archives \
                     '(\"epy\" . \
     \"https://jorgenschaefer.github.io/packages/\")) \
        (package-refresh-contents) \
        (package-install 'elpy))"

echo >>~/.emacs '(package-initialize)'
echo >>~/.emacs '(elpy-enable)'

