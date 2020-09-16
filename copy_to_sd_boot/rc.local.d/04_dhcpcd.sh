#!/bin/sh -e

if [ -e /boot/dhcpcd.conf ]
then
  cat /boot/dhcpcd.conf >> /etc/dhcpcd.conf
  mkdir -p /boot/done
  mv /boot/dhcpcd.conf /boot/done
  systemctl stop dhcpcd
  for dev in $(ip -4 -o addr list | grep -v ' lo ' | awk '{print $2}')
  do
    ip addr flush dev $dev
  done
  systemctl start dhcpcd
fi
