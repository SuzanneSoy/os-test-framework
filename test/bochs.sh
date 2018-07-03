#!/bin/sh
set -e

os_filename="example-os/os.bat"

bochsrc="$(mktemp)"
cat > "$bochsrc" <<EOF
floppya: 1_44=${os_filename}, status=inserted
boot: floppy
display_library: sdl
EOF

bochscontinue="$(mktemp)"
echo "continue" > "$bochscontinue"

bochs -qf "$bochsrc" < "$bochscontinue" &
pid=$!
runsikulix -r test/check-gradient.sikuli && exitcode=$? || exitcode=$?

./utils/take-screenshots.sh "./deploy-screenshots/$(basename "$0" .sh).png"

kill $pid

rm "${bochsrc}" "${bochscontinue}"

exit $exitcode
