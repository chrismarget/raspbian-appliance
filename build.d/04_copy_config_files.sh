#!/bin/sh -e

files=()
files+=('wpa_supplicant.conf')
files+=('hostname')
files+=('ssh')
files+=('authorized_keys')
files+=('user.lock')
files+=('sync')
files+=('dhcpcd.conf')
files+=('localization')

. $(dirname $0)/functions

if [ -z "$BOOT_MNT" ]
then
  error "boot mount unknown"
fi

if [ ! -d "$BOOT_MNT" ] 
then
  error "boot mount does not exist"
fi

if [ -z "$APPLIANCE_DIR" ]
then
  error "appliance dir unknown"
fi

if [ ! -d "$APPLIANCE_DIR" ]
then
  error "appliance dir does not exist"
fi

for file in ${files[*]}
do
  if [ -n "${PROJECT_DIR}" ] && [ -f "${PROJECT_DIR}/$file" ]
  then
    cp "${PROJECT_DIR}/$file" "$BOOT_MNT"
  elif [ -f "${APPLIANCE_DIR}/$file" ]
  then
    cp "${APPLIANCE_DIR}/$file" "$BOOT_MNT"
  fi
done
