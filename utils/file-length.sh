#!/bin/sh

set -e

if test $# -ne 2 || (test $# = 1 && test "$1" = "-h" -o "$1" = "--help"); then
  echo "Usage: $0 {-c|-l} path/to/file"
fi

wc "$1" "$2" | sed -e 's/^[[:space:]]*\([0-9][0-9]*\)[[:space:]].*$/\1/'
