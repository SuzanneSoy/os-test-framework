#!/bin/sh

if test "$#" -gt 1 -a "$1" = "-c"; then shift; fi
bash -euET -o pipefail -c 'trap "kill $$" ERR; '"$1"
exit $?
