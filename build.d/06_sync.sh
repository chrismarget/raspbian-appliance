#!/bin/sh

. $(dirname $0)/functions

[ -z "$BOOT_MNT" ] && error "boot mount unknown"
[ -z "$PROJECT_DIR" ] && error "project dir unknown"

[ -f "${PROJECT_DIR}/sync" ] && cp "${PROJECT_DIR}/sync" "$BOOT_MNT"
