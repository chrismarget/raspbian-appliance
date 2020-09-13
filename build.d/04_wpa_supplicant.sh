#!/bin/sh

. $(dirname $0)/functions

[ -z "$BOOT_MNT" ] && error "boot mount unknown"
if [ -f "${APPLIANCE_DIR}/wpa_supplicant.conf" ]
then
  cp ${APPLIANCE_DIR}/wpa_supplicant.conf ${BOOT_MNT}
fi
