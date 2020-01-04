#!/bin/bash

mount -t proc proc /proc
mount -t sysfs sys /sys


ROOT_PART_DEV=$(findmnt / -o source -n)
ROOT_PART_NAME=$(echo "$ROOT_PART_DEV" | awk -F '/' '{print $NF}')
ROOT_DEV_NAME=$(echo /sys/block/*/"${ROOT_PART_NAME}" | cut -d "/" -f 4)
ROOT_DEV="/dev/${ROOT_DEV_NAME}"
DISKID="$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

IFS=$'\n' read -d '' -r -a PARTS < <(fdisk -l $ROOT_DEV | egrep "^$ROOT_DEV" | awk '{print $1}')
IFS=$'\n' read -d '' -r -a MOUNTED < <(mount | grep $ROOT_DEV | awk '{print $1}')

UNMOUNTED=()

for p in ${PARTS[@]}
do
  echo ${MOUNTED[@]} | tr ' ' '\n' | egrep "^$p$"
  [ $? -ne 0 ] && UNMOUNTED+=$p
done

for p in ${UNMOUNTED[@]}
do
  pnum=$(echo $p | sed 's/^.*p//')
  set $(partx -s  $ROOT_DEV -g --nr $pnum:$pnum)
  PARTUUID="$6"
  set $(parted $ROOT_DEV print | egrep "^ $pnum ")
  TYPE=$6
  [ "$TYPE" == "fat32" ] && TYPE=vfat
  MOUNTPOINT="/mnt/$(fatlabel $p)"
  mkdir -p $MOUNTPOINT
  FSTAB="PARTUUID=$PARTUUID $MOUNTPOINT $TYPE defaults 0 2"
  echo "$FSTAB" >> /etc/fstab
done


IFS=$'\n' read -d '' -r -a PARTS < <(fdisk -d $raw_dev)


umount /proc
umount /sys
