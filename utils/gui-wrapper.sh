#!/bin/sh

set -e

resolution="$1" # e.g. 800x600x24 (width x height x bits_per_pixel)
shift           # the following arguments are the program to execute and its arguments

bg="$(mktemp --suffix='.png')"
anim="$(mktemp -d)"

# Create solid black background
convert -size "$(echo "$resolution" | cut -d 'x' -f1-2)" \
        tile:pattern:checkerboard \
        -auto-level +level-colors 'gray(192),gray(128)' \
        "$bg"

xvfb-run -a --server-args="-screen 0 ${resolution}" sh -c 'fluxbox 2>/dev/null & sleep 5; fbsetbg -f "'"$bg"'"; sleep 5; utils/screenshots-loop.sh "'"$anim"'" & "$@"' utils/gui-wrapper.sh-subshell "$@"

touch "$anim/stop-screenshots"
for i in `seq 60`; do if test -e "$anim/anim-done"; then break; fi; sleep 1; done
if test -e "$anim/anim.gif"; then
  mv "$anim/anim.gif" "./deploy-screenshots/$(basename "$1" .sh)-anim.gif"
fi
cp "$bg" "./deploy-screenshots/$(basename "$1" .sh)-bg-$(basename "$bg")"

# Cleanup
rm "$bg"
