The `build.d` directory contains scripts intended to be called
by `build.sh` while preparing the SD card.

Any executable ending with `.sh` will be run in lexical sort order.

The environment will include the following variables:
- `APPLIANCE_DIR` base directory of the raspbian-appliance project
- `PROJECT_DIR` base directory of the project; when rasbian-appliance is a submodule, this directory will be APPLIANCE_DIR/..
- `BOOT_MNT` current mount point of the pi's `/boot` directory
- `P3_LABEL` filesystem label of partition 3, controls the mount point for both MacOSX and rasbpian
- `P3_MNT` current mount point of partition 3 we've created for the pi
- `P4_LABEL` filesystem label of partition 4, controls the mount point for both MacOSX and rasbpian
- `P4_MNT` current mount point of partition 4 we've created for the pi
