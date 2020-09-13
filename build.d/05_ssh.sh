#!/bin/sh

. $(dirname $0)/functions

[ -n "$BOOT_MNT" ] || error "boot mount unknown"
[ -n "$APPLIANCE_DIR" ] || error "appliance dir unknown"

if [ -f "${APPLIANCE_DIR}/ssh" ] ||\
   [ -f "${APPLIANCE_DIR}/authorized_keys" ] ||\
   [ -f "${APPLIANCE_DIR}/copy_to_sd_boot/ssh" ] ||\
   [ -f "${APPLIANCE_DIR}/copy_to_sd_boot/authorized_keys" ]
then
  touch "${BOOT_MNT}/ssh"
  AKF="${APPLIANCE_DIR}/authorized_keys"
  [ -f "$AKF" ] && cp "$AKF" "${BOOT_MNT}"
fi
exit 0
