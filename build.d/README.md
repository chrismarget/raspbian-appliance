The `build.d` directory contains scripts intended to be called
by `build.sh` while preparing the SD card.

Any executable ending with `.sh` will be run in lexical sort order.

The environment will include the following variables:
- `PROJECT_DIR` base directory of the project
- `BOOT_MNT` current mount point of the pi's `/boot` directory
- `P3_MNT` current mount point of partition 3 we've created for the pi
- `P4_MNT` current mount point of partition 4 we've created for the pi
