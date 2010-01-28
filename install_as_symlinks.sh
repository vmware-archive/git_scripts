#!/bin/bash

if [ ! -f git-about ] ; then
  echo "You must run install.sh from the folder containing the git scripts"
  exit 1
fi

for file in git-* ; do
  ln -sf "`pwd`/$file" ~/bin/
done
