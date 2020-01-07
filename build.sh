#!/bin/bash

error() {
  echo "error: $1"
  exit 1
}

mount_wait () {
  tries=10
  while [ $tries -gt 0 ] && ! mount | egrep -q "^[^ ]*$1 "
  do
    sleep .1
    ((tries=$tries-1))
  done
  [ $tries -eq 0 ] && return 1
  return 0
}

get_options() {
  while getopts "i:c:d:3:4:" opt
  do
    case ${opt} in
      i )
        IMAGE="$OPTARG"
        ;;
      c )
        CKSUM="$OPTARG"
        ;;
      d )
        BSD_DEV="$OPTARG"
        ;;
      3 )
        P3SIZE=$(expr "$OPTARG" : '\([^:]*\)')
        P3LABEL=$(expr "$OPTARG" : '.*:\(.*\)')
        P3SIZE=${P3SIZE:-0}
        ;;
      4 )
        P4SIZE=$(expr "$OPTARG" : '\([^:]*\)')
        P4LABEL=$(expr "$OPTARG" : '.*:\(.*\)')
        P4SIZE=${P4SIZE:-0}
        ;;
      * )
        error "parsing options"
    esac
  done
  echo P3LABEL $P3LABEL
  echo P3SIZE  $P3SIZE
  echo P4LABEL $P4LABEL
  echo P4SIZE  $P4SIZE
  [ -z "$IMAGE" ] && error "must specify Raspbian image with \"-i <filename.zip>\""
  [ $P3SIZE -eq 0 ] && [ -n "$P3LABEL ] && error "partition 3 label specified for zero-length filesystem"
  [ $P4SIZE -eq 0 ] && [ -n "$P4LABEL ] && error "partition 4 label specified for zero-length filesystem"
  ([ -z "$P3LABEL" ] || check_8.3 $P3LABEL) || error "label $P3LABEL must be DOS 8.3 format"
  ([ -z "$P4LABEL" ] || check_8.3 $P4LABEL) || error "label $P4LABEL must be DOS 8.3 format"
}

check_8.3 () {
  if [[ "$1" =~ "." ]]
  then
    [[ "$1" =~ ^[a-zA-Z0-9]{1,8}.[a-zA-Z0-9]{1,3}$ ]] || return 1
  else
    [[ "$1" =~ ^[a-zA-Z0-9]{1,8}$ ]] || return 2
  fi
  return 0
}

do_checksum () {
  IMG_FILE=$1
  SUM_FILE=$2
  [ -z "$SUM_FILE" ] && return 0
  case $(basename "$SUM_FILE") in
    $(basename "${IMG_FILE}.sha1"))
      alg=1
      ;;
    $(basename "${IMG_FILE}.sha256"))
      alg=256
      ;;
    *)
      error "checksum file must be named '${IMG_FILE}.sha1' or '${IMG_FILE}.sha256'"
      ;;
  esac
  
  SUM=$(cut -d ' ' -f 1 $SUM_FILE)
  echo doing checksum $IMG_FILE $SUM_FILE
  echo "$SUM  $IMG_FILE" | shasum -a $alg -c -
  return $?
}

get_device_names () {
  [ -z "$BSD_DEV" ] && BSD_DEV=$(system_profiler SPCardReaderDataType | grep 'BSD Name:' | awk '{print $NF}' | head -1)
  [ -z "$BSD_DEV" ] && return 1
  BLK_DEV=/dev/$BSD_DEV
  RAW_DEV=/dev/r$BSD_DEV
}

write_image () {
  diskutil umountDisk force $2
  unzip -p $1 | dd obs=512k of=$2
  return $?
}

get_mount_point () {
  diskutil mountDisk $1 > /dev/null
  mount_wait $1 || error "$1 not mounted"
  echo $(mount | egrep "^[^ ]*$1 " | cut -d ' ' -f 3)
}

is_digit () {
  if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null
  then
    return 0
  fi
  return 1
}

add_partitions () {
  P3S=$1
  P4S=$2
  DEV=$3

  is_digit $P3SIZE || error "P3 size \"$P3SIZE\""
  is_digit $P4SIZE || error "P4 size \"$P4SIZE\""

  # Parse the current disk layout.
  IFS=$'\n' read -d '' -r -a PARTS < <(fdisk -d $DEV)
  TOTALBLOCKS=$(fdisk $DEV | grep $DEV | sed -E 's/^.*\[([0-9]+).*$/\1/')

  # Calculate desired disk layout.
  P3START=$(($TOTALBLOCKS-$P4SIZE-$P3SIZE))
  P4START=$(($TOTALBLOCKS-$P4SIZE))
  [ $P3SIZE -gt 0 ] && PARTS[2]=$P3START,$P3SIZE,0C,-,0,0,0,0,0,0
  [ $P4SIZE -gt 0 ] && PARTS[3]=$P4START,$P4SIZE,0C,-,0,0,0,0,0,0

  # Save the MBR ID because OSX fdisk will zero it
  MBR_ID=$(dd if=$DEV bs=1 skip=440 count=4)
  
  # repartition, fix the MBR ID
  diskutil umountDisk force $DEV
  echo ${PARTS[*]} | tr ' ' '\n' | fdisk -yr $DEV
  mount_wait ${DEV}s1
  diskutil umountDisk force $DEV
  echo -n $MBR_ID | sudo dd of=$DEV bs=1 seek=440
  mount_wait $DEV
  diskutil umountDisk force $DEV
}

mkfs () {
  DEV=$1
  LABEL=$2
  [ -n "$LABEL" ] && VOLOPT="-v $LABEL" || VOLOPT=""
  newfs_msdos -F 32 $VOLOPT $DEV
}

do_run_parts () {
  for i in ${1}/*sh
  do
    [ -e $i ] && $i
  done
}


main () {
  # Read CLI options
  get_options $@

  # Check the image file
  do_checksum $IMAGE $CKSUM || error "checksum failure"

  # Set device names
  get_device_names || error "finding sd device - consider setting it with -d option"

  # Write the image to the SD card
  write_image $IMAGE $RAW_DEV || error "writing image to sd card"
  mount_wait ${BLK_DEV}s1

  # Repartition
  add_partitions "$P3SIZE" "$P4SIZE" "$BLK_DEV"

  # Create new filessystems as necessary
  [ $P3SIZE -gt 0 ] && mkfs ${RAW_DEV}s3 $P3LABEL
  [ $P4SIZE -gt 0 ] && mkfs ${RAW_DEV}s4 $P4LABEL

  # Remount everything (straggler filesystems)
  diskutil umountDisk force $BSD_DEV
  diskutil mountDisk $BSD_DEV

  # The /boot filesystem should be automatically mounted by OSX. Find it.
  export BOOT_MNT=$(get_mount_point ${BLK_DEV}s1)
  [ -n "$BOOT_MNT"  ] || echo "${BLK_DEV}s1 device not mounted after imaging"

  # Copy scripts and whatnot to the /boot partition
  (cd $(dirname $0)/copy_to_sd_card && tar cLf - .) | (cd $BOOT_MNT; tar xf -)

  # Save the original cmdline.txt file for later reinstallation. We'll be
  # deploying a temporary version of this file that calls go-init.
  cp ${BOOT_MNT}/cmdline.txt ${BOOT_MNT}/cmdline.txt.orig

  # Build the go-init binary, copy it to the SD card
  GOOS=linux GOARCH=arm GOARM=5 go build -o ${BOOT_MNT}/go-init go-init/main.go


  # Export the mount point of extra partitions
  [ $P3SIZE -gt 0 ] && export P3_MNT=$(get_mount_point ${BLK_DEV}s3)
  [ $P4SIZE -gt 0 ] && export P4_MNT=$(get_mount_point ${BLK_DEV}s4)

  # run the post-build modules
  do_run_parts $(dirname $0)/build.d

}

main $@
diskutil umountDisk force $BSD_DEV
