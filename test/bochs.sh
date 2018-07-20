#!/bin/sh
set -e

if test $# -ne 1 || test "$1" = '-h' -o "$1" = '--help'; then
    echo "Usage: $0 operating_system_file"
fi
os_filename="$1"

cat > "build/bochsrc" <<EOF
floppya: 1_44=${os_filename}, status=inserted
boot: floppy
display_library: sdl
EOF

echo "continue" > "build/bochscontinue"

bochs -qf "build/bochsrc" < "build/bochscontinue" &
pid=$!
runsikulix -r test/check-gradient.sikuli && exitcode=$? || exitcode=$?

./utils/take-screenshots.sh "./deploy-screenshots/$(basename "$0" .sh).png"

kill $pid

exit $exitcode
