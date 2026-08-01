#!/bin/sh
# Dispatch a path to the directory or file preview. Used by Ctrl-T, which can
# select either. Kept as a script so it does not depend on whether fzf's $SHELL
# is sh or fish.
# usage: preview-path.sh PATH
p=$1
d=$(dirname -- "$0")

[ -e "$p" ] || exit 0

if [ -d "$p" ]; then
    "$d/preview-dir.sh" "$p"
else
    "$d/preview-file.sh" "$p"
fi
