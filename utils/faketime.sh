#!/bin/bash

set -euET -o pipefail

timestamp_iso_8601="$1"
shift

date_command() {
  # TODO: substring or case … in Darwin*)
  if test "$(uname -s)" = Darwin; then
    date -j -f '%Y-%m-%dT%H:%M:%S' "$(echo "${1}" | cut -c 1-19)" "${2}";
  else
    date -d "${1}" "${2}";
  fi
}

if which faketime >/dev/null; then
  ( set -x; faketime -f "$(date_command "${timestamp_iso_8601}" '+%Y-%m-%d %H:%m:%S')" "$@"; )
elif which datefudge >/dev/null; then
  ( set -x; datefudge --static "${timestamp_iso_8601}" "$@"; )
else
  echo "ERROR: command faketime or datefudge not found. Please install either command."
  exit 1
fi
