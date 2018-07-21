#!/bin/sh
set -e

if test $# -ne 1 || test "$1" = '-h' -o "$1" = '--help'; then
    echo "Usage: $0 operating_system_file"
fi
# Force the path to be relative or absolute, but with at least one /
# Otherwise, the command will be searched in the $PATH, instead of using the
# given file.
os_filename="$(dirname "$1")/$(basename "$1")"

osascript -e 'tell app "Terminal" to activate'
osascript -e 'tell app "Terminal" to do script "'"$PWD"'/os.bat"' &
pid=$!
runsikulix -r test/check-gui-sh-mac.sikuli && exitcode=$? || exitcode=$?

screencapture "./deploy-screenshots/$(basename "$0" .sh).png"

kill $pid || true

exit $exitcode
