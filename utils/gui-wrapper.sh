#!/bin/sh

set -e

resolution="$1" # e.g. 800x600x24 (width x height x bits_per_pixel)
shift           # the following arguments are the program to execute and its arguments

bg="build/checkerboard_$(echo "$resolution" | cut -d 'x' -f1-2).xbm"
twm_session_dir="$(./utils/mktemp.sh -d)"
anim="$(./utils/mktemp.sh -d)"

# Create checkerboard background
# Use +level-colors 'gray(192),gray(128)' to choose directly the colors.
#   Since we're creating an .xbm for xsetroot, we'll use black and white
#   and choose the colors with xsetroot.
convert -size "$(echo "$resolution" | cut -d 'x' -f1-2)" \
        tile:pattern:checkerboard \
        -auto-level \
        "$bg"

cat > "build/twm_cfg" <<EOF
RandomPlacement
EOF

echo "$bg $anim $resolution $@"
# -fg chocolate -bg coral looks nice too :)
xvfb-run -a --server-args="-screen 0 ${resolution}" sh -c 'sleep 2; SM_SAVE_DIR="'"$twm_session_dir"'" twm -f "'"build/twm_cfg"'" & sleep 1 && xsetroot -bitmap "'"$bg"'" -fg gray75 -bg gray50 && sleep 1 && ./utils/screenshots-loop.sh x11 "'"$anim"'" & "$@"' ./utils/gui-wrapper.sh-subshell "$@"

touch "$anim/stop-screenshots"
anim_done=false
for i in `seq 300`; do if test -e "$anim/anim-done"; then anim_done=true; break; fi; sleep 1; done
if $anim_done; then echo "anim: done ($*)"; else echo "anim: timeout ($*)"; fi
if test -e "$anim/anim.gif"; then
  mv "$anim/anim.gif" "./deploy-screenshots/$(basename "$1" .sh)-anim.gif"
fi

# Cleanup
rm -r -- "$twm_session_dir" "$anim"
