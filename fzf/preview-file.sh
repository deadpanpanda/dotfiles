#!/bin/sh
# File preview with the shared dim gutter. Same gutter format as preview.sh
# (used by rgf) and preview-dir.sh, so a file looks the same whichever picker
# you arrived from.
# usage: preview-file.sh FILE
f=$1
[ -r "$f" ] || exit 0

head -c 200000 -- "$f" 2>/dev/null \
    | awk 'NR > 200 { exit } { printf "  \033[2m%6d|\033[0m %s\n", NR, $0 }'
