#!/bin/sh

. $(dirname $0)/functions

[ -n "$BOOT_MNT" ] || error "boot mount unknown"
[ -n "$PROJECT_DIR" ] || error "appliance dir unknown"

if [ -f "${PROJECT_DIR}/ssh" ] ||\
   [ -f "${PROJECT_DIR}/authorized_keys" ] ||\
   [ -f "${PROJECT_DIR}/copy_to_sd_boot/ssh" ] ||\
   [ -f "${PROJECT_DIR}/copy_to_sd_boot/authorized_keys" ]
then
  touch "${BOOT_MNT}/ssh"
  AKF="${PROJECT_DIR}/authorized_keys"
  [ -f "$AKF" ] && cp "$AKF" "${BOOT_MNT}"
fi
exit 0
