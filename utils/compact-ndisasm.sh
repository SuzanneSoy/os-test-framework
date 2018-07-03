in=$1
out=$2

# Add -s 0x1234 to te ndisasm command-line to specify that there is an
# instruction starting at 0x1234. Use this when ndisasm misinterprets
# some instructions due to db.
skip=""
for i in `seq 0 255`; do skip="$skip -s 0x7e$(printf %02x $i)"; done
(echo "[BITS 16]"; \
 echo "[ORG 0x7c00]"; \
 ndisasm -s 0x7c78 $skip -o 0x7C00 "$in" \
 | uniq -s 8 -c \
 | sed -r -e 's/^\s*1 //; t; s/^\s*([0-9]+) ([^ ]+\s+[^ ]+\s+)/\2times \1 /' \
 | sed -r -e 's/([^ ]+\s+[0-9A-F]{4}\s+j[^ ]+ )0x/\1short 0x/') > "$out"
# The last sed line just above fixes an issue with ndisasm
# (it fails to annotate jz and jnc (and possibly other) with short).
