#!/bin/sh

set -e

if test $# -ne 1 || test "$1" = "-h" -o "$1" = "--help"; then
  echo "Usage: $0 path/to/screenshots/directory"
  exit 1
fi
screenshots_dir="$1"

for i in `seq 100`; do
  if test -e "$screenshots_dir/stop-screenshots"; then
    break
  fi
  scrot "$screenshots_dir/$(printf %03d.png $i)" || break
  sleep 0.2
done

if test -n "$(find "$screenshots_dir/" -maxdepth 1 -type f -name '*.png')"; then
  convert $(ls "$screenshots_dir"/*.png | sort) "$screenshots_dir/anim.gif"
fi

touch "$screenshots_dir/anim-done"
