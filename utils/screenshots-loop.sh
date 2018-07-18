#!/bin/sh

set -e

usage() {
  echo "Usage: $0 {x11|mac} path/to/screenshots/directory"
}

if test $# -ne 2 || test "$1" = "-h" -o "$1" = "--help"; then
  usage
  exit 1
fi
platform="$1"
screenshots_dir="$2"

case $platform in
    x11) screenshot_tool=scrot;;
    mac) screenshot_tool=screencapture;;
    *) usage; exit 1;;
esac


for i in `seq 100`; do
  if test -e "$screenshots_dir/stop-screenshots"; then
    break
  fi
  "$screenshot_tool" "$screenshots_dir/$(printf %03d.png $i)" || break
  sleep 0.2
done

if test -n "$(find "$screenshots_dir/" -maxdepth 1 -type f -name '*.png')"; then
  convert $(ls "$screenshots_dir"/*.png | sort) "$screenshots_dir/anim.gif"
fi

touch "$screenshots_dir/anim-done"
