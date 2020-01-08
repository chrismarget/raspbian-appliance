#!/bin/sh

# Comment out the entire contents of /etc/rc.local, especially 'exit 0'
sed -i 's/^\([^#]\)/#\1/' /etc/rc.local 

cat >> /etc/rc.local << EOF

[ -e /boot/rc.local ] && /boot/rc.local
EOF
