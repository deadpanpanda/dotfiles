#!/bin/sh
# Search by name across BOTH filesystems and format results for a picker.
#
#   Windows drives : the Everything index via es.exe (instant, no walk)
#   WSL home       : a live fd walk (ext4 is fast enough to redo per keystroke)
#
# Everything cannot see /home, because WSL's ext4 lives in a virtual disk it
# has no access to, hence the second source.
#
# es.exe returns Windows paths with CRLF endings, so strip the CR and rewrite
# "C:\a\b" as "/mnt/c/a/b".
#
# Output is two tab-separated fields:
#   1. display  - filename (with query matches highlighted), then dimmed folder
#   2. fullpath - the real path, hidden from the picker, used to cd
#
# Filtering for both sources happens in the awk below, so the two behave
# identically: case-insensitive substring, space-separated terms ANDed. That
# mirrors Everything's default matching.
#
# usage: es-search.sh [QUERY]
ES=/mnt/c/Tools/es.exe
ES_LIMIT=5000
WSL_ROOT=$HOME
TOTAL_LIMIT=20000

q=$1

{
    if [ -x "$ES" ]; then
        if [ -z "$q" ]; then
            "$ES" -n "$ES_LIMIT" 2>/dev/null
        else
            "$ES" -n "$ES_LIMIT" "$q" 2>/dev/null
        fi \
            | tr -d '\r' \
            | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\):|/mnt/\l\1|'
    fi

    # Package caches dominate the WSL home and are never navigation targets:
    # excluding them takes the walk from 293,807 entries to 29,579.
    fdfind --hidden \
        --exclude '.git' --exclude 'node_modules' --exclude '.npm' \
        --exclude '.nuget' --exclude '.cache' --exclude '.local' \
        --exclude '.venv*' --exclude '__pycache__' \
        . "$WSL_ROOT" 2>/dev/null
} \
    | awk -v q="$q" '
BEGIN {
    NAMEC = "\033[1;36m"   # filename
    DIM   = "\033[2m"      # folder
    HL    = "\033[1;31m"   # matched substring
    R     = "\033[0m"
    WIDTH = 40             # filename column before the folder starts
    nterms = split(tolower(q), T, /[ \t]+/)
}

function highlight(name,   lname, t, tl, start, r, abs, k, i, c, out, inhl) {
    delete marks
    lname = tolower(name)
    for (t = 1; t <= nterms; t++) {
        tl = length(T[t])
        if (tl == 0) continue
        start = 1
        while (1) {
            r = index(substr(lname, start), T[t])
            if (r == 0) break
            abs = start + r - 1
            for (k = abs; k < abs + tl; k++) marks[k] = 1
            start = abs + 1
        }
    }
    out = NAMEC
    inhl = 0
    for (i = 1; i <= length(name); i++) {
        c = substr(name, i, 1)
        if (marks[i] && !inhl)      { out = out HL;      inhl = 1 }
        else if (!marks[i] && inhl) { out = out R NAMEC; inhl = 0 }
        out = out c
    }
    return out R
}

{
    full = $0
    sub(/\/$/, "", full)          # fd marks directories with a trailing slash
    if (full == "") next

    p = 0
    for (j = length(full); j > 0; j--) {
        if (substr(full, j, 1) == "/") { p = j; break }
    }
    if (p > 0) { dir = substr(full, 1, p - 1); name = substr(full, p + 1) }
    else       { dir = "";                     name = full }

    # Same matching rules for both sources.
    lname = tolower(name)
    for (t = 1; t <= nterms; t++) {
        if (T[t] != "" && index(lname, T[t]) == 0) next
    }

    pad = WIDTH - length(name)
    if (pad < 1) pad = 1
    spaces = sprintf("%" pad "s", "")

    printf "%s%s%s%s%s\t%s\n", highlight(name), spaces, DIM, dir, R, full
    if (++shown >= '"$TOTAL_LIMIT"') exit
}'
