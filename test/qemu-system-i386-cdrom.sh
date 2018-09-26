#!/bin/sh
set -e

if test $# -ne 1 || test "$1" = '-h' -o "$1" = '--help'; then
    echo "Usage: $0 operating_system_file"
    exit 1
fi
os_filename="$1"

qemu-system-i386 -drive format=raw,readonly,file=${os_filename},index=0,if=ide,index=1,media=cdrom -boot d &
pid=$!
runsikulix -r test/check-gradient.sikuli && exitcode=$? || exitcode=$?

./utils/take-screenshots.sh "./deploy-screenshots/$(basename "$0" .sh).png"

kill $pid

exit $exitcode
