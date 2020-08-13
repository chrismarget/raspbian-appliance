#!/bin/sh

if [ -e /boot/authorized_keys ]
then
  mkdir -p 0700 /home/pi/.ssh
  mv /boot/authorized_keys /home/pi/.ssh
  chmod 0600 /home/pi/.ssh/authorized_keys
  chown -R pi:pi /home/pi/.ssh
fi
