#!/bin/sh

. $(dirname $0)/functions

if [ -z "$BOOT_MNT" ] || [ ! -e "$BOOT_MNT" ]
then
  error "/boot mount point unknown"
fi

cat > $BOOT_MNT/rc.local << EOF
#!/bin/sh

# Template start script
# This script will be copied to the SD card at /boot/rc.local
# On boot, it's called by /etc/rc.local

EOF
