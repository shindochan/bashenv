#! /bin/bash
sudo easy_install pip
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

