#!/bin/sh

if [ -n "$BOOT_MNT" ]
then
  echo installing ds3231 driver
  echo "dtoverlay=i2c-rtc,ds3231" >> $BOOT_MNT/config.txt
fi
