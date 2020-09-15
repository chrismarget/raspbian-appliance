#!/bin/sh -e
exit 0

if [ -e /boot/dhcpcd.conf ]
then
  cat /boot/dhcpcd.conf >> /etc/dhcpcd.conf
fi

rm /boot/dhcpcd.conf "$0"
