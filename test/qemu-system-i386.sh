#!/bin/sh
set -e

os_file="example-os/os.sh"

qemu-system-i386 -drive format=raw,file=${os_file},index=0,if=floppy &
pid=$!
~/sikulix/runsikulix -r test/check-gradient.sikuli
kill $pid