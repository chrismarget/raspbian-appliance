#!/bin/sh

. functions

if [ -z "$BOOT_MNT" ] || [ ! -e "$BOOT_MNT" ]
then
  error "/boot mount point unknown"
fi

cp $(dirname $0)/data/rc.local $BOOT_MNT/rc.local

cat > $BOOT_MNT/rc.local << EOF
#!/bin/sh

# Template start script
# This script will be copied to the SD card at /boot/rc.local
# On boot, it's called by /etc/rc.local

EOF
