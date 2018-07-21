#!/bin/sh

set -e

if test $# -ne 1 || test "$1" = "-h" -o "$1" = "--help"; then
  echo "Usage: $0 [/]absolute/or/relative/path"
fi

case "$1" in
  /*) echo "$1";;
  *) echo "$PWD/$1";;
esac
