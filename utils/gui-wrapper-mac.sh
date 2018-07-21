#!/bin/sh

set -e

resolution="$1" # e.g. 800x600x24 (width x height x bits_per_pixel)
shift           # the following arguments are the program to execute and its arguments

bg="$(./utils/absolute-path.sh "build/checkerboard_$(echo "$resolution" | cut -d 'x' -f1-2).png")"
anim="$(./utils/mktemp.sh -d)"

echo "$anim $resolution $@"
sleep 2
   osascript -e "tell application \"Finder\" to set desktop picture to (POSIX file \"$bg\")" \
|| osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$bg\""
sleep 1
./utils/screenshots-loop.sh mac "$anim" &
"$@"

touch "$anim/stop-screenshots"
anim_done=false
for i in `seq 300`; do if test -e "$anim/anim-done"; then anim_done=true; break; fi; sleep 1; done
if $anim_done; then echo "anim: done ($*)"; else echo "anim: timeout ($*)"; fi
if test -e "$anim/anim.gif"; then
  mv "$anim/anim.gif" "./deploy-screenshots/$(basename "$1" .sh)-anim.gif"
fi

# Cleanup
rm -r -- "$anim"
