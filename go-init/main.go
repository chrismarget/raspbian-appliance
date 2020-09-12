package main

import (
	"golang.org/x/sys/unix"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"
)

const (
	tmpPath           = "/tmp"
	bootPath          = "/boot"
	rootDevName       = "mmcblk0p2"
	devPath           = "/dev/"
	mntPath           = "/mnt/"
	rootPath          = "/"
	rootDev           = tmpPath + devPath + rootDevName
	rootMnt           = tmpPath + mntPath + rootDevName
	initDirSuffix     = ".d"
	shellScriptSuffix = ".sh"
)

func main() {
	var err error

	log.Println("Mounting filesystems...")
	err = mountFileSystems()
	if err != nil {
		log.Fatalf("mountFileSystems failed: %s", err.Error())
	}

	log.Printf("Running init scripts in %s...", filepath.Join(bootPath, os.Args[0]+initDirSuffix))
	err = runParts(filepath.Join(bootPath, os.Args[0]+initDirSuffix))
	if err != nil {
		log.Fatalf("runParts failed: %s", err.Error())
	}

	log.Println("Unmounting filesystems...")
	err = unMountFileSystems()
	if err != nil {
		log.Fatalf("unMountFileSystems failed: %s", err.Error())
	}

	_ = syscall.Reboot(syscall.LINUX_REBOOT_CMD_RESTART)
}

func mountFileSystems() error {
	var err error

	log.Printf("    Mounting VFAT root read/write...")
	err = unix.Mount(rootPath, rootPath, "vfat", syscall.MS_REMOUNT, "")
	if err != nil {
		return err
	}

	log.Printf("    Creating %s directory...", tmpPath)
	err = os.MkdirAll(tmpPath, 1777)
	if err != nil {
		return err
	}

	log.Printf("    Mounting tmpfs on %s...", tmpPath)
	err = unix.Mount("", tmpPath, "tmpfs", 0, "")
	if err != nil {
		return err
	}

	log.Printf("    Creating %s directory...", filepath.Dir(rootDev))
	err = os.MkdirAll(filepath.Dir(rootDev), 0700)
	if err != nil {
		return err
	}

	log.Printf("    Creating device node %s...", rootDev)
	err = unix.Mknod(rootDev, 0660|syscall.S_IFBLK, 179<<8|2)
	if err != nil {
		return err
	}

	log.Printf("    Creating %s directory...", rootMnt)
	err = os.MkdirAll(rootMnt, 0700)
	if err != nil {
		return err
	}

	log.Printf("    Mounting ext4 root on %s...", rootMnt)
	err = unix.Mount(rootDev, rootMnt, "ext4", 0, "")
	if err != nil {
		return err
	}

	log.Printf("    Pivoting root and boot filesystems into place...")
	err = unix.PivotRoot(rootMnt, rootMnt+bootPath)
	if err != nil {
		return err
	}

	return nil
}

func runParts(dir string) error {
	files, err := ioutil.ReadDir(dir)
	if err != nil {
		return err
	}

	var scripts []string
	for _, f := range files {
		if f.Mode().IsRegular() && strings.HasSuffix(f.Name(), shellScriptSuffix) {
			scripts = append(scripts, f.Name())
		}
	}
	sort.Strings(scripts)
	for _, s := range scripts {
		s = filepath.Join(dir, s)
		log.Printf("    Running %s", s)
		cmd := exec.Command(s)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		err = cmd.Run()
		if err != nil {
			log.Printf("%s produced an error.\n", s)
			time.Sleep(10 * time.Second)
			return err
		}
	}
	return nil
}

func unMountFileSystems() error {
	var err error

	log.Printf("    Pivoting SD card partitions back to their original mount points...")
	err = unix.PivotRoot(bootPath, filepath.Join(bootPath, rootMnt))
	if err != nil {
		return err
	}

	log.Printf("    Unmounting the root FS from %s...", rootMnt)
	err = unix.Unmount(rootMnt, 0)
	if err != nil {
		return err
	}

	log.Printf("    Unmounting tmpfs from %s...", tmpPath)
	err = unix.Unmount(tmpPath, 0)
	if err != nil {
		return err
	}

	log.Printf("    Unmounting vfatroot from %s...", rootPath)
	err = unix.Unmount(rootPath, 0)
	if err != nil {
		return err
	}
	return nil
}
