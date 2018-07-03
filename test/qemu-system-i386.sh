#!/bin/sh
set -e

os_filename="example-os/os.bat"

qemu-system-i386 -drive format=raw,file=${os_filename},index=0,if=floppy &
pid=$!
runsikulix -r test/check-gradient.sikuli && exitcode=$? || exitcode=$?

./utils/take-screenshots.sh "./deploy-screenshots/$(basename "$0" .sh).png"

kill $pid

exit $exitcode
