#!/bin/sh -e

if [ -e /boot/dhcpcd.conf ]
then
  cat /boot/dhcpcd.conf >> /etc/dhcpcd.conf
  mkdir -p /boot/done
  mv /boot/dhcpcd.conf /boot/done
fi
