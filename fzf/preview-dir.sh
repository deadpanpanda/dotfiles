#!/bin/sh
# Directory listing for a preview pane, with the shared dim gutter.
# usage: preview-dir.sh DIR
p=$1
[ -d "$p" ] || exit 0

eza --icons --group-directories-first --color=always -- "$p" 2>/dev/null \
    | awk '{ printf "  \033[2m%6d|\033[0m %s\n", NR, $0 }' \
    | head -200
