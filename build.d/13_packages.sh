#!/bin/bash

. $(dirname $0)/functions

[ -n "$PROJECT_DIR" ] || error "PROJECT_DIR unset"
[ -n "$P3_MNT" ] || error "P3_MNT unset"
[ -d "$P3_MNT" ] || error "partition 3 should be mounted, but isn't"
[ -n "$P3_LABEL" ] || error "P3_LABEL unset"
[ -n "$BOOT_MNT" ] || error "BOOT_MNT unset"
[ -d "$BOOT_MNT" ] || error "/boot partition should be mounted, but isn't"

pkg_list=${PROJECT_DIR}/packages.txt

# we store the downloaded packages in cache_dir:
cache_dir="${PROJECT_DIR}/.build.cache"
mkdir -p "$cache_dir"

# we put the downloaded packages on the SD card here:
pkg_dir="pkgs"
build_pkg_dir="${P3_MNT}/$pkg_dir"
mkdir -p $build_pkg_dir

# when the pi is running, it needs to know both the mount point
# and the directory where the packages will be found:
pi_pkg_mp="/opt/${P3_LABEL}"
pi_pkg_dir="${pi_pkg_mp}/$pkg_dir"

# loop line-by-line over $pkg_list
while read line
do
  set $line

  # ignore lines containing more than two "words"
  if [ $# -ne 2 ]
  then
    continue
  fi

  hash=$1
  link=$2

  # ensure sum portion contains only valid characters
  if [[ ! $hash =~ ^[0-9a-fA-F]*$ ]]
  then
    continue
  fi

  # sha1/sha2 produce sums of specific lengths. ignore others.
  case ${#hash} in
    40) ;;
    64) ;;
    96) ;;
    129) ;;
    *) continue ;;
  esac

  # Fetch the file if we don't already have it.
  file="${cache_dir}/$(basename $link)"
  [ -f "$file" ] || (echo -e "\nFeching $link..."; curl -o "$file" "$link")

  echo -n "Checking $file... "
  shasum -c - <<< "$hash  $file" && cp $file $build_pkg_dir && packages_exist="y"
done <<< "$([ -f $pkg_list ] && cat $pkg_list)"

# write a self-destructing startup script to the pi
if [ -n "$packages_exist" ]
then
  start_script="${BOOT_MNT}/rc.local.d/01_pkg_install.sh"
  echo "#!/bin/sh" > $start_script
  echo "dpkg -i ${pi_pkg_dir}/*" >> $start_script
  echo "rm \$0" >> $start_script
fi
