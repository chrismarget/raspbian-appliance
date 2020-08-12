#!/bin/sh

# This script patches files included on the Rasbian image, but
# unavailable to the OSX build host because they're in a Linux
# filesystem.
#
# To add a new patch:
#   1) add the original filename to patch.d/targets.txt
#   2) create the patch
#   3) save the patch in patch.d/<md5-of-original-file><optional-comment>.patch
#
# In practice, that might look like:
#   ORIG=/path/to/orig/file
#   NEW=/path/to/new/file
#   SUM=$(md5sum $ORIG | awk '{print $1}')
#   diff $ORIG $NEW > ${SUM}.<comment>.patch

error () {
  echo "---------------------------"
  echo "$1"
  echo "---------------------------"
  sleep 5
  exit 1
}       

PATCHDIR=$(dirname $0)/patch.d
TARGETLIST=${PATCHDIR}/targets.txt

ls -l $PATCHDIR
sleep 3

for TARGET in $(cat $TARGETLIST)
do
  SUM=$(md5sum $TARGET | awk '{print $1}')
  [ ${#SUM} -eq 32 ] || error "unable to checksum $TARGET"
  [ $(ls ${PATCHDIR}/${SUM}*.patch | wc -l) -le 0 ] && error "No patchfile for ${SUM} found in $PATCHDIR"
  [ $(ls ${PATCHDIR}/${SUM}*.patch | wc -l) -ge 2 ] && error "Multiple patchfiles matching ${SUM} found in $PATCHDIR"
  PATCHFILE=$(ls ${PATCHDIR}/${SUM}*.patch)
  patch $TARGET < $PATCHFILE
done
