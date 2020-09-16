#!/bin/sh -e

. $(dirname $0)/functions

if [ -z "$BOOT_MNT" ]
then
  error "boot mount unknown"
fi

if [ ! -d "$BOOT_MNT" ]
then
  error "boot mount not found"
fi

if [ -f "${BOOT_MNT}/authorized_keys" ] && [ ! -f "${BOOT_MNT}/ssh" ]
then
  touch "${BOOT_MNT}/ssh"
fi
