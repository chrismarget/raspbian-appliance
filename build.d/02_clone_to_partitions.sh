#!/bin/sh

. $(dirname $0)/functions

[ -n "$APPLIANCE_DIR" ] || error "APPLIANCE_DIR unknown"
[ -n "$BOOT_MNT" ] || error "boot partition mount point unknown"
[ -d "$BOOT_MNT" ] || error "boot partition should be mounted, but isn't"

[ -n "$P3_MNT" ] && ([ -d "$P3_MNT" ] || echo "partition 3 should be mounted, but isn't")
[ -n "$P4_MNT" ] && ([ -d "$P4_MNT" ] || echo "partition 4 should be mounted, but isn't")
sleep 2
[ -n "$P3_MNT" ] && ([ -d "$P3_MNT" ] || error "partition 3 should be mounted, but isn't")
[ -n "$P4_MNT" ] && ([ -d "$P4_MNT" ] || error "partition 4 should be mounted, but isn't")

(cd "${APPLIANCE_DIR}/copy_to_sd_boot" && tar cLf - --exclude README.md .) | (cd "$BOOT_MNT"; tar xf -)
if [ -d "${PROJECT_DIR}/copy_to_sd_boot" ]
then
  (cd "${PROJECT_DIR}/copy_to_sd_boot" && tar cLf - --exclude README.md .) | (cd "$BOOT_MNT"; tar xf -)
fi

if [ -n "$P3_MNT" ]
then
  (cd "${APPLIANCE_DIR}/copy_to_sd_p3" && tar cLf - --exclude README.md .) | (cd "$P3_MNT"; tar xf -)
  if [ -d "${PROJECT_DIR}/copy_to_sd_p3" ]
  then
    (cd "${PROJECT_DIR}/copy_to_sd_p3" && tar cLf - --exclude README.md .) | (cd "$P3_MNT"; tar xf -)
  fi
fi

if [ -n "$P4_MNT" ]
then
  (cd "${APPLIANCE_DIR}/copy_to_sd_p4" && tar cLf - --exclude README.md .) | (cd "$P4_MNT"; tar xf -)
  if [ -d "${PROJECT_DIR}/copy_to_sd_p4" ]
  then
    (cd "${PROJECT_DIR}/copy_to_sd_p4" && tar cLf - --exclude README.md .) | (cd "$P4_MNT"; tar xf -)
  fi
fi
