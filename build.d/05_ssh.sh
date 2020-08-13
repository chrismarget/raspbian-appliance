#!/bin/sh

. $(dirname $0)/functions

[ -z "$BOOT_MNT" ] && error "boot mount unknown"
[ -z "$PROJECT_DIR" ] && error "project dir unknown"

if [ -f "${PROJECT_DIR}/ssh" ]
then
  touch "${BOOT_MNT}/ssh"
  AKF="${PROJECT_DIR}/authorized_keys"
  [ -f "$AKF" ] && cp "$AKF" "${BOOT_MNT}"
fi
