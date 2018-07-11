#!/bin/sh
set -e

if test $# -ne 1 || test "$1" = '-h' -o "$1" = '--help'; then
    echo "Usage: $0 operating_system_file"
fi
# Force the path to be relative or absolute, but with at least one /
# Otherwise, the command will be searched in the $PATH, instead of using the
# given file.
os_filename="$(dirname "$1")/$(basename "$1")"

xterm -e ${os_filename} &
pid=$!
runsikulix -r test/check-gui-sh.sikuli && exitcode=$? || exitcode=$?

./utils/take-screenshots.sh "./deploy-screenshots/$(basename "$0" .sh).png"

kill $pid

exit $exitcode
