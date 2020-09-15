#!/bin/sh -e

. "$(dirname $0)/functions"

[ -n "$BOOT_MNT" ] || error "boot partition mount point unknown"
[ -d "$BOOT_MNT" ] || error "boot partition should be mounted, but isn't"

# Try to find a "hostname" file, copy it to BOOT_MNT
if [ -n "${PROJECT_DIR}" ] && [ -r "${PROJECT_DIR}/hostname" ]
then
  cp "${PROJECT_DIR}/hostname" "$BOOT_MNT"
elif [ -r "${APPLIANCE_DIR}/hostname" ]
then
  cp "${APPLIANCE_DIR}/hostname" "$BOOT_MNT"
fi

# Try to find a "dhcpcd.conf" file, copy it to BOOT_MNT
if [ -n "${PROJECT_DIR}" ] && [ -r "${PROJECT_DIR}/dhcpcd.conf" ]
then
  cp "${PROJECT_DIR}/dhcpcd.conf" "$BOOT_MNT"
elif [ -r "${APPLIANCE_DIR}/dhcpcd.conf" ]
then
  cp "${APPLIANCE_DIR}/dhcpcd.conf" "$BOOT_MNT"
fi
