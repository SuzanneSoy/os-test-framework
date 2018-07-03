#!/bin/sh

set -e

resolution="$1" # e.g. 800x600x24 (width x height x bits_per_pixel)
shift           # the following arguments are the program to execute and its arguments

bg="$(mktemp --suffix='bg.png')"
fb_cfg="$(mktemp --suffix='fluxbox.cfg')"

# Create solid black background
convert -size 16x16 xc:black "$bg"

# Create minimalist fluxbox configuration
cat > "$fb_cfg" <<EOF
background:	fullscreen
background.pixmap:	$bg
EOF

xvfb-run -a --server-args="-screen 0 ${resolution}" sh -c 'fluxbox -rc '"$fb_cfg"' 2>/dev/null & sleep 3; "$@"' utils/gui-wrapper.sh-subshell "$@"

# Cleanup
rm "$bg" "$fb_cfg"