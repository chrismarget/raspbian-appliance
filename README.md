# raspbian-appliance
Tooling for building Raspberry Pi appliances based on Raspbian

## What?
This a minimal set of software to turn a Raspbian image file into an SD card prepped for a particular purpose (an appliance) on Mac OSX.

## Why?
First, Raspbian makes some unfortunate assumptions like:
- The root filesystem is going to be the last one on the SD card, and it should be immediately stretched to fill the entire disk on first boot.
- Any customization the end user might be interested in doing will be accomplished manually either via SSH or with a monitor and keyboard.

Second, it's not very easy to interact with the SD card's root filesystem from a MacBook. The only filesystem we can touch is `/boot`, and there's not much you can do from there. There are ext4 drivers that make this possible, but I'm trying to make this easy to consume.

Third, I want to make appliance images that start with the trusted (for some meanings of that term) Raspbian image, rather than delivering (and requiring end users to trust) a large binary image that I might produce.

## How?
Roughly speaking, the process looks like this:
1) Write the disk image to an SD card in the usual way.
2) Make changes to the only accessible (from a MacBook) partition: `/boot`

## No, really: How?
1) Write the disk image to an SD card in the usual way.
2) Drop a replacement for Raspbian's `init` onto the `/boot` filesystem.
3) Replace the Kernel Command Line file `cmdline.txt` with one that references the our new program: `go-init`
4) On first boot, `go-init` makes our desired changes, then gets out of the way.

## What does go-init do?
`go-init` does exactly 3 things:
1) Mounts the `/` and `/boot` filesystems in their usual locations.
2) Runs all the shell scripts found in `/boot/go-init.d/*.sh`. That's the VFAT filesystem that Mac OSX can see and change. Those files live in `copy_to_sd_card/go-init.d/` within this project. They're run in lexical sort order and must be named with the `.sh` suffix.
3) Cleanly unmounts the filesystems and reboots the Pi.

The `01_restore_kcl_file.sh` script replaces `cmdline.txt` with `cmdline.txt.orig` (the original Raspbian file is saved there by `build.sh`), restoring normal system behavior. Without that step, go-init would run in an eternal reboot loop.

Add additional scripts here to make the Pi do whatever you need (install packages, drop startup scripts in place, etc...)

## Okay, but the `boot` filesystem is too small!
Yeah. That's a problem, and was the genesis of this whole project. By default, Raspian's first boot calls `/usr/lib/raspi-config/init_resize.sh` to stretch the root partition/filesystem, and it throws an error if you've added extra partitions. So, on the *actual* first boot, `go-init.d/02_patch_init_resize.sh` modifies Raspbian's `init_resize.sh` to adjust its expectations about `/root` growing all the way to the end of the SD card. With that change we can add extra partitions to the end of the SD card during the intial setup. Our appliance software can then live there. The `build.sh` script includes some variables that control the size and labels of those filesystems.

## What's `build.sh` do?
That's how I typically run the build. Specifically, I do:

    sudo ./build.sh
    
It does the following:
1) Installs the Raspbian zip file to the SD card. Variables at the top of this script specify the Raspbian image location and checksum. The SD card is auto-detected (on my MacBook, anyway).
2) Sets aside the original `cmdline.txt` as `cmdline.txt.orig`  for restoration by `01_restore_kcl_file.sh`
3) Builds and installs the `go-init` binary (tested with go1.13.4)
4) Copies the contents of `copy_to_sd_card/` to the SD card's `/boot` partition. This includes the temporary `cmdline.txt` file and the scripts in `go-init.d`
5) Adds additional partitions as needed (see `P[34]SIZE` and `P[34]LABEL` variables) to the end of the SD card.
