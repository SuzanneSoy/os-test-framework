#!/bin/bash

set -e

file="$1"
width="$2"

colors=(78,78,78 255,108,96 0,170,0 288,288,182 150,203,254 255,115,253 85,255,255 238,238,238 124,124,124 255,155,147 177,253,121 255,255,145 181,220,254 255,156,254 85,255,255 255,255,255)
args=()
for i in `seq 0 15`; do
  if test $i -ge 8; then
    color=$((i+8))
  else
    color=$((i))
  fi
  args+=(-fuzz 0% -fill "gray(${color})" -opaque "rgb(${colors[$i]})")
done

   convert "$file" -resize "${width}x" png:- \
 | convert +dither -remap "$(dirname "$0")/travis-palette.gif" png:- gif:- \
 | convert gif:- "${args[@]}" gif:- \
 | convert gif:- pgm:- \
 | tail -n +4 \
 | hexdump -Cv \
 | sed -n -e 's/^[0-9a-f]*  \(\([0-9a-f]\{2\}  \?\)\{1,16\}\).*$/\1/p' \
 | tr '\n' ' ' \
 | sed -e 's/  \+/ /g' \
 | fold -w $((width*3)) \
 | while read a && read b; do for i in $a; do echo -n "$i ${b%% *} "; b="${b#* }"; done; echo; done \
 | fold -w $((width*6)) \
 | sed -e 's/\([01]\)\([0-7]\) \([01]\)\([0-7]\) /[\1;3\2;4\4m▀/g' -e 's/$/[m/' \
 | if test "$CI" = "true" -a "$TRAVIS" = "true"; then sed -e 's/▀/"/g'; else cat; fi
# Using the line below instead of the one above will ensure that the output is
# printed slow enought that unicode corruption by Travis is unlikely.
#
# | if test "$CI" = "true" -a "$TRAVIS" = "true"; then while IFS=$'\n' read -n 11 ab; do if test "${#ab}" -ne 11; then echo "$ab"; else echo -n "$ab"; fi; sleep 0.01; done; else cat; fi
echo

