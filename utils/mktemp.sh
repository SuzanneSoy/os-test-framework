#!/bin/sh

set -e

the_tmp_dir="${_CS_DARWIN_USER_TEMP_DIR:-"${TMPDIR:-"/tmp"}"}/"

if test $# -ge 1 && test "$1" = "-d"; then
  shift
  mkdir_opt='-d'
else
  mkdir_opt=''
fi

if test $# -gt 0; then
  echo "Usage: $0 [-d]" >&2
  exit 1
fi

result="$(mktemp $mkdir_opt "${the_tmp_dir}/tmp.XXXXXXXXXX")"

# Sanity checks:

# Something went wrong while creating the file or directory:
if ! test -e "$result"; then echo "MKTEMP_SH_ERROR"; exit 1; fi
# This could result in a very bad rm invocation:
if ! test "$result" != "/"; then echo "MKTEMP_SH_ERROR"; exit 1; fi
# Something went wrong while creating the file:
if test "x$mkdir_opt" = "x" && ! test -f "$result"; then echo "MKTEMP_SH_ERROR"; exit 1; fi
# Something went wrong while creating the directory:
if test "x$mkdir_opt" = "x-d" && ! test -d "$result"; then echo "MKTEMP_SH_ERROR"; exit 1; fi

echo "$result"
