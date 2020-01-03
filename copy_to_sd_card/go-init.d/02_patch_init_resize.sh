#!/bin/sh

# This script patches Raspbian's init_resize.sh to make it friendly to
# SD cards which have had extra partitions added prior to first boot.
# Raspbian's default behavior is to error if the root partition isn't
# the last partition on the device, because it wants to stretch the
# rootfs all the way to the last block. These changes cause it to
# stretch within the available contiguous space instead.

error () {
  echo "---------------------------"
  echo "$1"
  echo "---------------------------"
  sleep 5
  exit 1
}       

TARGET="/usr/lib/raspi-config/init_resize.sh"
SUM=$(md5sum $TARGET)

[ -n "$SUM" ] || error "unable to checksum $TARGET"

case $SUM in
  30b53c84508cdb01aa3b1057a4ccebee) B64PATCH="
      OTksMTAzZDk4CjwgICBpZiBbICIkUk9PVF9QQVJUX05VTSIgLW5lICIkTEFTVF9Q
      QVJUX05VTSIgXTsgdGhlbgo8ICAgICBGQUlMX1JFQVNPTj0iUm9vdCBwYXJ0aXRp
      b24gc2hvdWxkIGJlIGxhc3QgcGFydGl0aW9uIgo8ICAgICByZXR1cm4gMQo8ICAg
      ZmkKPCAKMTI4YTEyNCwxMzkKPiAKPiAgIGZvciBQQVJUX0JFR0lOIGluICQoZWNo
      byAiJFBBUlRJVElPTl9UQUJMRSIgfCBlZ3JlcCAnXlswLTldOicgfCBhd2sgLUY6
      ICd7cHJpbnQgJDJ9JykKPiAgIGRvCj4gICAgIGlmIFsgJFBBUlRfQkVHSU4gLWd0
      ICRST09UX1BBUlRfRU5EIF0gJiYgWyAkUEFSVF9CRUdJTiAtbHQgJFRBUkdFVF9F
      TkQgXQo+ICAgICB0aGVuCj4gICAgICAgVEFSR0VUX0VORD0kKCgkUEFSVF9CRUdJ
      TiAtIDEpKQo+ICAgICBmaQo+ICAgZG9uZQo+IAo+ICAgZm9yIFBBUlRfQkVHSU4g
      aW4gJChlY2hvICIkUEFSVElUSU9OX1RBQkxFIiB8IGVncmVwICdeWzAtOV06JyB8
      IGF3ayAtRjogJ3twcmludCAkMn0nKQo+ICAgZG8KPiAgICAgaWYgWyAkUEFSVF9C
      RUdJTiAtZ3QgJFJPT1RfUEFSVF9FTkQgXSAmJiBbICRQQVJUX0JFR0lOIC1sdCAk
      VEFSR0VUX0VORCBdCj4gICAgIHRoZW4KPiAgICAgICBUQVJHRVRfRU5EPSQoKCRQ
      QVJUX0JFR0lOIC0gMSkpCj4gICAgIGZpCj4gICBkb25lCg==" ;;
esac

[ -n "$B64PATCH" ] || error "unknown version of $TARGET with checksum: $SUM"

echo $PATCH | base64 --decode | patch /usr/lib/raspi-config/init_resize.sh
