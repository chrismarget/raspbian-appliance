#!/bin/sh

# This script patches Raspbian's init_resize.sh to make it friendly to
# SD cards which have had extra partitions added prior to first boot.
# Raspbian's default behavior is to error if the root partition isn't
# the last partition on the device, because it wants to stretch the
# rootfs all the way to the last block. These changes cause it to
# stretch within the available contiguous space instead.

error () {
  echo "---------------------------"
  echo "$1"
  echo "---------------------------"
  sleep 5
  exit 1
}       

TARGET="/usr/lib/raspi-config/init_resize.sh"
SUM=$(md5sum $TARGET | awk '{print $1}')

[ -n "$SUM" ] || error "unable to checksum $TARGET"

PATCHDIR=$(dirname $0)/patch.d/init_resize_patches

[ -e "$PATCHDIR/$SUM.patch" ] || error "No patchfile $SUM.patch found in $PATCHDIR"

patch /usr/lib/raspi-config/init_resize.sh < $PATCHDIR/$SUM.patch
