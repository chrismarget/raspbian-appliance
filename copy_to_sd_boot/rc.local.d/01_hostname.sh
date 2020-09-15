#!/bin/sh -e
exit 0

if [ -e /boot/hostname ]
then
  raspi-config nonint do_hostname "$(cat /boot/hostname)"
fi

rm /boot/hostname "$0"
