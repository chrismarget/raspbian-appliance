#!/bin/bash

# Specify rasbian image file and checksum (both found on
# https://downloads.raspberrypi.org/raspbian/images).
IMAGE=~/Downloads/2018-03-13-raspbian-stretch.zip
SHA256SUM=d6d64a8bfad37de6bc7d975a335c69b8c6164a33b1ef0c79c888a9b83db5063f

# Specify desired size (512-byte blocks) and volume label of new partitions
# 3 and 4.  Set size to 0 if additional partion(s) not needed.
P3SIZE=200000
P3LABEL=PART3
P4SIZE=500
P4LABEL=PART4

# Set paths relevant to this project.
FILES4BOOT=copy_to_sd_card

mount_wait () {
  tries=100
  while [ $tries -ge 0 ] && [ "$(mount | grep $1)" == "" ]
  do
    sleep .1
    ((tries=$tries-1))
  done
  return $tries
}

# Validate the checksum.
echo "$SHA256SUM  $IMAGE" | shasum -a 256 -c || badcksum=yes
[ "$badcksum" != "yes" ] || echo "bad checksum"
[ "$badcksum" != "yes" ] || exit 1

# Determine the device name of the MacBook built-in SD reader.
BSD_NAME=$(system_profiler SPCardReaderDataType | grep 'BSD Name:' | awk '{print $NF}' | head -1)
[ -n "$BSD_NAME" ] || echo "no SD device found."
[ -n "$BSD_NAME" ] || exit 2
blk_dev=/dev/$BSD_NAME
raw_dev=/dev/r$BSD_NAME

# Write the image to the SD card.
diskutil umountDisk $BSD_NAME
unzip -p $IMAGE | dd obs=512k of=$raw_dev

# The VFAT component (/boot) of the raspbian image
# should mount automatically. Find it.
mount_wait ${BSD_NAME}s1
BOOT_MNT=$(mount | grep ${BSD_NAME}s1 | awk '{print $3}')
[ -n "$BOOT_MNT"  ] || echo "device not mounted after imaging"
[ -n "$BOOT_MNT"  ] || exit 3

# Save the original cmdline.txt file for later reinstallation. We'll be
# deploying a temporary version of this file that calls go-init.
cp ${BOOT_MNT}/cmdline.txt ${BOOT_MNT}/cmdline.txt.orig

# Build the go-init binary.
GOOS=linux GOARCH=arm GOARM=5 go build -o ${BOOT_MNT}/go-init go-init/main.go

# Copy everything to the VFAT filesystem. This includes stuff we want on there
# right now (cmdline.txt and go-init) plus the tar file that will be unrolled
# onto the ext4 filesystem by go-init. Then unmount the disk.
(cd $FILES4BOOT; tar cLf - .) | (cd $BOOT_MNT; tar xf -)
diskutil umountDisk $BSD_NAME

# Exit here if additional partitions aren't needed.
[ $P3SIZE -ne 0 ] || [ $P4SIZE -ne 0 ] || exit

# Parse the current disk layout.
IFS=$'\n' read -d '' -r -a PARTS < <(fdisk -d $raw_dev)
TOTALBLOCKS=$(fdisk $raw_dev | grep $raw_dev | sed -E 's/^.*\[([0-9]+).*$/\1/')

# Calculate desired disk layout.
P3START=$(($TOTALBLOCKS-$P4SIZE-$P3SIZE))
P4START=$(($TOTALBLOCKS-$P4SIZE))
[ $P3SIZE -gt 0 ] && PARTS[2]=$P3START,$P3SIZE,0C,-,0,0,0,0,0,0
[ $P4SIZE -gt 0 ] && PARTS[3]=$P4START,$P4SIZE,0C,-,0,0,0,0,0,0

# Repartition the disk, collecting and restoring the MBR identifier.
MBR_ID=$(dd if=$blk_dev bs=1 skip=440 count=4)


echo ${PARTS[*]} | tr ' ' '\n' | fdisk -yr $raw_dev
echo -n $MBR_ID | sudo dd of=$blk_dev bs=1 seek=440
mount_wait $BSD_NAME
diskutil umountDisk $BSD_NAME

# Add new partitions 3 and 4
if [ $P3SIZE -gt 0 ]
then
  [ -n "$P3LABEL" ] && VOLOPT="-v $P3LABEL" || VOLOPT=""
  newfs_msdos -F 32 $VOLOPT ${BSD_NAME}s3
fi

if [ $P4SIZE -gt 0 ]
then
  [ -n "$P4LABEL" ] && VOLOPT="-v $P4LABEL" || VOLOPT=""
  newfs_msdos -F 32 $VOLOPT ${BSD_NAME}s4
fi

diskutil umountDisk $BSD_NAME
