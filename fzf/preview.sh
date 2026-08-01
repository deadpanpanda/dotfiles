#!/bin/sh
# Preview a window of lines around a match.
#
# The matched line gets three cues: a yellow left bar, a bold yellow line
# number, and a background tint across the whole row. Occurrences of the query
# are highlighted by ripgrep itself, so matching rules stay identical to the
# search.
#
# usage: preview.sh FILE LINE [QUERY]
f=$1
n=${2:-1}
q=$3

[ -r "$f" ] || exit 0

start=$((n - 10))
[ "$start" -lt 1 ] && start=1
end=$((n + 30))

# Highlight the raw text first, then add gutters. Doing it in this order stops
# a numeric query from matching the line numbers we add.
window=$(awk -v s="$start" -v e="$end" 'NR > e { exit } NR >= s' "$f")

if [ -n "$q" ]; then
    marked=$(printf '%s\n' "$window" \
        | rg --color=always --smart-case --passthru -- "$q" 2>/dev/null) \
        || marked=$window
else
    marked=$window
fi

printf '%s\n' "$marked" | awk -v s="$start" -v target="$n" '
BEGIN {
    R   = "\033[0m"
    BG  = "\033[48;5;238m"
    BAR = "\033[1;33m\342\226\214" R
    NUM = "\033[1;33m"
    DIM = "\033[2m"
}
{
    ln = s + NR - 1
    line = $0
    if (ln == target) {
        # ripgrep emits a reset after every match, which would end the row
        # background early. Re-open it after each one.
        gsub(/\033\[0m/, R BG, line)
        printf "%s %s%s%6d%s %s%s\n", BAR, BG, NUM, ln, R BG, line, R
    } else {
        printf "  %s%6d|%s %s\n", DIM, ln, R, line
    }
}'
