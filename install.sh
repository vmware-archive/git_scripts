#!/bin/bash

if [ ! -f git-about ] ; then
  echo "You must run install.sh from the folder containing the git scripts"
  exit 1
fi

for file in git-* ; do
  rm -f ~/bin/$file
  cp -v $file ~/bin
done
