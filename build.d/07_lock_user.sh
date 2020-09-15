#!/bin/sh -e

. $(dirname $0)/functions

[ -n "$BOOT_MNT" ] || error "boot partition mount point unknown"
[ -d "$BOOT_MNT" ] || error "boot partition should be mounted, but isn't"
[ -d "$PROJECT_DIR" ] || error "project dir not available"

LOCK_FILE="${PROJECT_DIR}/user.lock"

if [ -f "$LOCK_FILE" ]
then
  cp "$LOCK_FILE" "$BOOT_MNT"
  START_SCRIPT="${BOOT_MNT}/rc.local.d/10_lock_user.sh"
  mkdir -p "$(dirname $START_SCRIPT)"
  cat > "$START_SCRIPT" << EOF
#!/bin/sh
cat /boot/user.lock | while read line
do
  echo \$line | xargs -n 1 usermod -L
done
rm /boot/user.lock
rm \$0
EOF
fi
