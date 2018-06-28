#!/bin/sh

screenshot="$(tempfile --suffix=".png")"

scrot "$screenshot"
"$(dirname "$0")/to_ansi.sh" "$screenshot" 131