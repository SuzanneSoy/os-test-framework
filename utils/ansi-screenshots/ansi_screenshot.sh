#!/bin/sh

screenshot="$(mktemp --suffix=".png")"

scrot "$screenshot"
"$(dirname "$0")/to_ansi.sh" "$screenshot" 107

rm "$screenshot"
