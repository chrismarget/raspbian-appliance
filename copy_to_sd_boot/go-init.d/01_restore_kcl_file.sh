#!/bin/sh

# This script moves the original kernel command line (probably the original
# Raspbian first-boot directive referencing init_resize.sh) into place
# (probably overwriting the file that references go-init).

[ -e /boot/cmdline.txt.orig ] && mv /boot/cmdline.txt.orig /boot/cmdline.txt
