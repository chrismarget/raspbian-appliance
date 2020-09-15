#!/bin/sh -e

if [ -e /boot/hostname ]
then
  raspi-config nonint do_hostname "$(cat /boot/hostname)"
  mkdir -p /boot/done
  mv /boot/hostname /boot/done
fi
