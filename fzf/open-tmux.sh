#!/bin/sh
# Open a file in a new tmux window, named after the file, at a given line.
#
# The window's working directory is set to the file's folder, so the shell you
# get after quitting the editor is already in the right place.
#
# usage: open-tmux.sh FILE [LINE]
f=$1
n=${2:-1}

[ -n "$f" ] || exit 0
[ -n "$TMUX" ] || exit 0   # nothing sensible to do outside tmux

# rgf searches ".", so matches come back as "./a/b.py". tmux does not resolve
# -c against the calling shell's directory, and the editor would be handed a
# relative path from a changed cwd, so absolutise first.
case "$f" in
    /*) ;;
    *)  f=$PWD/${f#./} ;;
esac

name=$(basename -- "$f")
dir=$(dirname -- "$f")
ed=${EDITOR:-nvim}

tmux new-window -n "$name" -c "$dir" "$ed" "+$n" "$f"
