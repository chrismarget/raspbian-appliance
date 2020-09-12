#!/bin/bash

mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devtmpfs devtmpfs /dev

ROOT_PART_DEV=$(findmnt / -o source -n)
ROOT_PART_NAME=$(echo "$ROOT_PART_DEV" | awk -F '/' '{print $NF}')
ROOT_DEV_NAME=$(echo /sys/block/*/"${ROOT_PART_NAME}" | cut -d "/" -f 4)
ROOT_DEV="/dev/${ROOT_DEV_NAME}"
DISKID="$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

PARTS=()
for p in $(fdisk -l $ROOT_DEV | egrep "^$ROOT_DEV" | awk '{print $1}')
do
  PARTS+=($(basename $p))
done

MOUNTED=()
for m in $(mount | grep $ROOT_DEV | awk '{print $1}')
do
  MOUNTED+=($(basename $m))
done

UNMOUNTED=()
for p in ${PARTS[@]}
do
  echo ${MOUNTED[@]} | tr ' ' '\n' | egrep -q "^$p$"
  [ $? -ne 0 ] && UNMOUNTED+=($p)
done

for p in ${UNMOUNTED[@]}
do
  pnum=$(echo $p | sed 's/^.*p//')
  set $(partx -s  $ROOT_DEV -g --nr $pnum:$pnum)
  PARTUUID="$6"
  set $(parted $ROOT_DEV print | egrep "^ $pnum ")
  TYPE=$6
  [ "$TYPE" == "fat32" ] && TYPE=vfat
  LABEL="$(fatlabel /dev/$p)"
  [ -z "$LABEL" ] && continue
  MOUNTPOINT="/opt/$(fatlabel /dev/$p)"
  mkdir -p $MOUNTPOINT
  FSTAB="PARTUUID=$PARTUUID $MOUNTPOINT $TYPE defaults 0 2"
  echo "$FSTAB" >> /etc/fstab
done

if [ -f /boot/sync ]
then
  sed -i 's/^\(PARTUUID.*defaults\)/\1,sync/' /etc/fstab
fi

umount /dev
umount /proc
umount /sys
