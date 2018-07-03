#!/bin/sh

set -e

resolution="$1" # e.g. 800x600x24 (width x height x bits_per_pixel)
shift           # the following arguments are the program to execute and its arguments

bg="$(mktemp --suffix='.png')"
anim="$(mktemp -d)"

# Create solid black background
convert -size "$(echo "$resolution" | cut -d 'x' -f1-2)" tile:pattern:checkerboard "$bg"

xvfb-run -a --server-args="-screen 0 ${resolution}" sh -c 'fluxbox 2>/dev/null & sleep 5; fbsetbg -f "'"$bg"'"; sleep 5; (for i in `seq 100`; do scrot "'"$anim"'/$(printf %03d.png $i)"; sleep 0.2; done) & "$@"' utils/gui-wrapper.sh-subshell "$@"

convert $(ls "$anim"/*.png | sort) ./deploy-screenshots/anim.gif

# Cleanup
rm "$bg"
