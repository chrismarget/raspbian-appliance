#!/bin/sh -e

. $(dirname $0)/functions

[ -n "$BOOT_MNT" ] || error "boot partition mount point unknown"
[ -d "$BOOT_MNT" ] || error "boot partition should be mounted, but isn't"
[ -d "$PROJECT_DIR" ] || error "project dir not available"

LOCK_FILE="${PROJECT_DIR}/user.lock"

if [ -f "$LOCK_FILE" ]
then
  cp "$LOCK_FILE" "$BOOT_MNT"
fi
