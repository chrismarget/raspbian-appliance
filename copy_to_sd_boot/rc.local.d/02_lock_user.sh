#!/bin/sh

if [ -e /boot/user.lock ]
then
  cat /boot/user.lock | while read line
  do
    echo $line | xargs -n 1 usermod -L
  done
  mkdir -p /boot/done
  mv /boot/user.lock /boot/done
fi
