#!/bin/sh
set -e

os_file="example-os/os.sh"

bochsrc="$(tempfile)"
cat > "$bochsrc" <<EOF
floppya: 1_44=${os_file}, status=inserted
boot: floppy
EOF

bochscontinue="$(tempfile)"
echo "continue" > "$bochscontinue"

bochs -qf "$bochsrc" < "$bochscontinue" &
pid=$!
runsikulix -r test/check-gradient.sikuli
kill $pid
