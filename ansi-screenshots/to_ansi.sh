#!/bin/bash

file="$1"
width="$2"

mini_png="$(tempfile --suffix=".png")"
colors_gif="$(tempfile --suffix=".gif")"
indexed_gif="$(tempfile --suffix=".gif")"
indexed_pgm="$(tempfile --suffix=".pgm")"

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

   convert "$file" -resize "${width}x" "${mini_png}" \
&& convert +dither -remap "$(dirname "$0")/travis-palette.gif" "${mini_png}" "${colors_gif}" \
&& convert "${colors_gif}" "${args[@]}" "${indexed_gif}" \
&& convert "${indexed_gif}" "${indexed_pgm}" \
&& tail -n +4 "${indexed_pgm}" \
 | hexdump -Cv \
 | sed -n -r -e 's/^[0-9a-f]*  (([0-9a-f]{2} ){8}) (([0-9a-f]{2} ){7}[0-9a-f]{2}).*$/\1\3/p' \
 | tr '\n' ' ' \
 | fold -w $((width*3)) \
 | sed -r -e 's/([01])([0-7]) /[\1;3\2m█/g' \
 | if test "$CI" = "true" -a "$TRAVIS" = "true"; then while read ab; do echo "$ab"; sleep 0.05; done; else cat; echo; fi
