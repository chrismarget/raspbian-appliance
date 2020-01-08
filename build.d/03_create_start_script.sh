#!/bin/sh

if [ -z "$BOOT_MNT" ] || [ ! -e "$BOOT_MNT" ]
then
  echo "/boot mount point unknown"
fi

cp $(dirname $0)/data/rc.local $BOOT_MNT/rc.local
