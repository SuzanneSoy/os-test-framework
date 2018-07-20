#!/bin/sh

set -e

screenshot="$("$(dirname "$0")/../mktemp.sh" .png)"

scrot "$screenshot"
"$(dirname "$0")/to_ansi.sh" "$screenshot" 128

rm "$screenshot"
