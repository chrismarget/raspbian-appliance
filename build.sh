#!/bin/bash -e

error() {
  >&2 echo "error: $1"
  exit 1
}

set_project_dir () {
  if [ "$(ls -i ${APPLIANCE_DIR}/../$(readlink "$APPLIANCE_DIR/../$(basename $0)") | cut -d ' ' -f 1)" == "$(ls -i $(readlink $0) | cut -d ' ' -f 1)" ]
  then
    PROEJCT_DIR=$(cd "$APPLIANCE_DIR/.."; pwd)
  else
    PROJECT_DIR=$APPLIANCE_DIR
  fi
  local BASE_DIR="$(cd "$(dirname "$0")"; pwd)"
  if [ -d "${BASE_DIR}/raspbian-appliance" ]
  then
    export PROJECT_DIR="${BASE_DIR}/raspbian-appliance"
  else
    export PROJECT_DIR="$BASE_DIR"
  fi
}

set_appliance_dir () {
  APPLIANCE_DIR=$(cd $(dirname $(readlink $0)); pwd)
}

read_config () {
  local CFG=${0/.sh/.cfg}
  CFG="$PROJECT_DIR/$(basename $CFG)"
  if [ -e $CFG ]
  then
    . $CFG
  fi
}

fetch_files () {
  CACHE_DIR="${0/.sh/.cache}"
  CACHE_DIR="$(dirname $CACHE_DIR)/.$(basename $CACHE_DIR)"
  mkdir -p "$CACHE_DIR"

  if [ -z "$IMAGE" ] && [ -n "$IMAGE_URL" ]
  then
    local IMAGE_FILE="${CACHE_DIR}/$(basename $IMAGE_URL)"
    [ -e "$IMAGE_FILE" ] || (echo -e "\nFetching $IMAGE_URL" && curl -o "$IMAGE_FILE" "$IMAGE_URL") || error "downloading $IMAGE_URL"
    IMAGE=$IMAGE_FILE
  fi

  if [ -z "$CKSUM" ] && [ -n "$CKSUM_URL" ]
  then
    local CKSUM_FILE="${CACHE_DIR}/$(basename $CKSUM_URL)"
    [ -e "$CKSUM_FILE" ] || (echo -e "\nFetching $CKSUM_URL" && curl -o "$CKSUM_FILE" "$CKSUM_URL") || error "downloading $CKSUM_URL"
    CKSUM=$CKSUM_FILE
  fi
}

wait_for_mount () {
  tries=100
  while [ $tries -gt 0 ] && ! mount | egrep -q "^[^ ]*$1 "
  do
    sleep .1
    ((tries=$tries-1))
  done
  [ $tries -eq 0 ] && >&2 echo "wait_for_mount $1 timed out"
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
        P3LABEL=$(expr "$OPTARG" : '.*:\(.*\)')
        P3SIZE=$(expr "$OPTARG" : '\([^:]*\)')
        ;;
      4 )
        P4LABEL=$(expr "$OPTARG" : '.*:\(.*\)')
        P4SIZE=$(expr "$OPTARG" : '\([^:]*\)')
        ;;
      * )
        error "parsing options"
    esac
  done
  export P3SIZE=${P3SIZE:-0}
  export P4SIZE=${P4SIZE:-0}
}

check_params () {
  [ -z "$IMAGE" ] && error "Raspbian image not specified"
  [ $P3SIZE -eq 0 ] && [ -n "$P3LABEL" ] && error "partition 3 label specified for zero-length filesystem"
  [ $P4SIZE -eq 0 ] && [ -n "$P4LABEL" ] && error "partition 4 label specified for zero-length filesystem"
  [ $P3SIZE -gt 0 ] && [ -z "$P3LABEL" ] && error "partition 3 size specified with empty label"
  [ $P4SIZE -gt 0 ] && [ -z "$P4LABEL" ] && error "partition 4 size specified with empty label"
  ([ -z "$P3LABEL" ] || check_dos_8.3 $P3LABEL) || error "label $P3LABEL must be DOS 8.3 format"
  ([ -z "$P4LABEL" ] || check_dos_8.3 $P4LABEL) || error "label $P4LABEL must be DOS 8.3 format"
  [ "$P3LABEL" == "$P4LABEL" ] && [ -n "$P3LABEL" ] && error "don't use the same filesystem label twice"
  [ "$(echo $P3LABEL | tr 'A-Z' 'a-z')" == "boot" ] && error "don't name a filesystem 'boot'"
  [ "$(echo $P4LABEL | tr 'A-Z' 'a-z')" == "boot" ] && error "don't name a filesystem 'boot'"
  return 0
}

check_dos_8.3 () {
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
  echo -n "Checking $IMG_FILE... "
  echo "$SUM  $IMG_FILE" | shasum -a $alg -c -
  return $?
}

get_device_name () {
  # Check for macbook built-in SD reader
  if [ -z "$BSD_DEV" ]
  then
    BSD_DEV=$(system_profiler SPCardReaderDataType | grep 'BSD Name:' | awk '{print $NF}' | head -1)
  fi

  # Catalina only: Check for external media
  if [ -z "$BSD_DEV" ]
  then
    DISKS=()
    for fullpath in $(diskutil list | egrep "^/dev/disk[0-9]+ .*external" | awk '{print $1}')
    do
      bn=$(basename $fullpath)
      DISKS+=($bn)
    done


    if [ ${#DISKS[@]} -eq 0 ]
    then
      error "Cannot find any SD cards"
    fi

    if [ ${#DISKS[@]} -gt 1 ]
    then
      error "Unable to chose between ${DISKS[@]}, please set BSD_DEV environment variable, or add to configuraiton file"
    fi

    BSD_DEV=$DISKS
    [ -z "$BSD_DEV" ] && error "get_device_name couldn't select a disk"
  fi
  BLK_DEV=/dev/$BSD_DEV
  RAW_DEV=/dev/r$BSD_DEV
}

confirm_device () {
  maybedisk=$1
  preamble=$(diskutil list $maybedisk)
  question="Overwrite ${maybedisk}?"
  if ! get_yes_no "$preamble" "$question" y
  then
    exit 1
  fi
}

# call with 3 args: preamble, question, default
get_yes_no () {
  # set up default answer + yesno prompt
  case $3 in
    y|yes|Y|YES) yesno="[Y/n]: "
                 deflt=0;;
    n|no|N|NO)   yesno="[y/N]: "
                 deflt=1;;
    *)           yesno="[y/n]: "
                 deflt="";;
  esac

  # print preamble
  echo "$1"

  while true
  do
    # print question
    echo -n "$2 $yesno"
    read r
    case $r in
      y|yes|Y|YES) return 0;;
      n|no|N|NO) return 1;;
      "") [ -n "$deflt" ] && return $deflt
    esac
  done
}

write_image () {
  out=$(diskutil umountDisk force $2) || error "$out"
  unzip -p $1 | dd ibs=512 obs=512k of=$2
  return $?
}

get_mount_point () {
  diskutil mountDisk $1 > /dev/null
  wait_for_mount $1 || error "$1 not mounted"
  echo $(mount | egrep "^[^ ]*$1 " | cut -d ' ' -f 3)
}

is_digits () {
  if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null
  then
    return 0
  fi
  return 1
}

add_partitions () {
  local P3SIZE=$1
  local P4SIZE=$2
  local RAWDEV=$3

  is_digits $P3SIZE || error "partition 3 size: \"$P3SIZE\" must be numeric"
  is_digits $P4SIZE || error "partition 4 size: \"$P4SIZE\" must be numeric"

  # Parse the current disk layout.
  PARTS=()
  while read PART
  do
    PARTS+=("$PART")
  done < <(fdisk -d $RAWDEV)

  TOTALBLOCKS=$(fdisk $RAWDEV | grep $RAWDEV | sed -E 's/^.*\[([0-9]+).*$/\1/')
  LASTUSED=$(echo ${PARTS[*]} | tr ' ' '\n' | awk -F, '{print $2}' | sort -n | tail -1)

  # Calculate desired disk layout.
  P3START=$(($TOTALBLOCKS-$P4SIZE-$P3SIZE))
  P4START=$(($TOTALBLOCKS-$P4SIZE))

  [ $P3START -gt $LASTUSED ] || error "Partition 3 starts in preallocated disk space"
  [ $P4START -gt $LASTUSED ] || error "Partition 4 starts in preallocated disk space"

  [ $P3SIZE -gt 0 ] && PARTS[2]=$P3START,$P3SIZE,0C,-,0,0,0,0,0,0
  [ $P4SIZE -gt 0 ] && PARTS[3]=$P4START,$P4SIZE,0C,-,0,0,0,0,0,0

  # Save the MBR ID because OSX fdisk will zero it
  MBR_ID=$(dd if=$RAWDEV bs=1 skip=440 count=4 2>/dev/null)
  
  # repartition
  out=$(diskutil umountDisk force $RAWDEV) || error "$out"
  echo ${PARTS[*]} | tr ' ' '\n' | fdisk -yr $RAWDEV 2>/dev/null
  wait_for_mount ${RAWDEV}s1 || error "partition 1 didn't re-mount after call to fdisk"

  # fix MBR ID
  out=$(diskutil umountDisk force $RAWDEV) || error "$out"
  echo -n $MBR_ID | sudo dd of=$RAWDEV bs=1 seek=440 2>/dev/null
  wait_for_mount ${RAWDEV}s1 || error "partition 1 didn't re-mount after fixing MBR ID"

  out=$(diskutil umountDisk force $RAWDEV) || error "$out"
}

mkfs () {
  DEV=$1
  LABEL=$2
  [ -n "$LABEL" ] && VOLOPT="-v $LABEL" || VOLOPT=""
  newfs_msdos -F 32 $VOLOPT $DEV
}

do_run_parts () {
  export BOOT_MNT=$(get_mount_point ${BLK_DEV}s1)
  [ $P3SIZE -gt 0 ] && export P3_MNT=$(get_mount_point ${BLK_DEV}s3) && export P3_LABEL=$P3LABEL
  [ $P4SIZE -gt 0 ] && export P4_MNT=$(get_mount_point ${BLK_DEV}s4) && export P4_LABEL=$P4LABEL

  for i in ${1}/*sh
  do
    echo ${i}...
    [ -e $i ] && $i
  done
}


main () {
  # Support for running as a submodule inside another project
  set_appliance_dir
  set_project_dir

  # Read CLI options
  get_options $@

  # Read config file
  read_config

  # Set device name
  get_device_name || error "finding sd device - consider setting it with -d option"

  # Confirm device before overwrite
  confirm_device $BSD_DEV
  
  # fetch files specified by URL
  fetch_files

  # validate
  check_params

  # Check the image file
  [ -n "$CKSUM" ] && (do_checksum $IMAGE $CKSUM || error "checksum failure")

  # Write the image to the SD card
  echo "Writing $IMAGE to SD card..."
  write_image $IMAGE $RAW_DEV || error "writing image to sd card"
  wait_for_mount ${BLK_DEV}s1

  # Repartition
  ([ $P3SIZE -gt 0 ] || [ $P4SIZE -gt 0 ]) && echo "Adding extra partition(s) to SD card..."
  add_partitions "$P3SIZE" "$P4SIZE" "$BLK_DEV"

  # Create new filessystems as necessary
  ([ $P3SIZE -gt 0 ] || [ $P4SIZE -gt 0 ]) && echo "Writing filesystems to new partition(s)..."
  [ $P3SIZE -gt 0 ] && mkfs ${RAW_DEV}s3 $P3LABEL
  [ $P4SIZE -gt 0 ] && mkfs ${RAW_DEV}s4 $P4LABEL

  # Remount everything (straggler filesystems)
  diskutil mount ${BSD_DEV}s1
  [ $P3SIZE -gt 0 ] && diskutil mount ${BSD_DEV}s3
  [ $P4SIZE -gt 0 ] && diskutil mount ${BSD_DEV}s4

  # Build the go-init binary
  BINDIR="${APPLIANCE_DIR}/copy_to_sd_boot"
  mkdir -p "$BINDIR"
  (cd "${APPLIANCE_DIR}/go-init"; GOOS=linux GOARCH=arm GOARM=5 go build -i -o ${BINDIR}/go-init main.go)

  # run the post-build modules
  echo "Running scripts in $APPLIANCE_DIR/build.d/"
  do_run_parts "${APPLIANCE_DIR}/build.d"
}

main $@

diskutil umountDisk force $BSD_DEV
