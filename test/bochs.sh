#!/bin/sh
set -e

os_file="example-os/os.sh"

bochsrc="$(mktemp)"
cat > "$bochsrc" <<EOF
floppya: 1_44=${os_file}, status=inserted
boot: floppy
display_library: sdl
EOF

bochscontinue="$(mktemp)"
echo "continue" > "$bochscontinue"

bochs -qf "$bochsrc" < "$bochscontinue" &
pid=$!
runsikulix -r test/check-gradient.sikuli

./utils/take-screenshots.sh "$(basename "$0" .sh).png"

kill $pid

rm "${bochsrc}" "${bochscontinue}"
