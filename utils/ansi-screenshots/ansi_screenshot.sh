#!/bin/sh

set -e

screenshot="$(mktemp --suffix=".png")"

scrot "$screenshot"
"$(dirname "$0")/to_ansi.sh" "$screenshot" 128

rm "$screenshot"
