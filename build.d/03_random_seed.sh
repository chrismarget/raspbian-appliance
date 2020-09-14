#!/bin/sh -e

. $(dirname $0)/functions

[ -z "$BOOT_MNT" ] && error "boot mount unknown"

urandom=/dev/urandom
seed="${BOOT_MNT}/random-seed"

err="$(dd if=$urandom of=$seed bs=512 count=1 2>&1)" || error "$err"
