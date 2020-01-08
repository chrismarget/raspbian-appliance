#!/bin/sh

. $(dirname $0)/functions

[ -z "$BOOT_MNT" ] && error "boot mount unknown"
cp ${BOOT_MNT}/cmdline.txt ${BOOT_MNT}/cmdline.txt.orig
