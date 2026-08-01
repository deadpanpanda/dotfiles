function fdf --description 'Find anything by name across Windows drives and WSL; enter cd\'s to the result, or to a file\'s folder'
    set -l query (string join ' ' $argv)

    set -l es /mnt/c/Tools/es.exe
    if not test -x "$es"
        echo "fdf: es.exe not found at $es" >&2
        echo "     download the Everything CLI from voidtools and place it there" >&2
        echo "     (WSL results will still work without it)" >&2
    end

    # fzf runs --bind and --preview commands through $SHELL. Force POSIX sh so
    # the snippets below are not parsed as fish.
    set -lx SHELL (command -v sh)

    set -l search "$HOME/.local/share/fzf/es-search.sh"

    set -l q_esc (string replace -a "'" "'\\''" -- $query)
    set -lx FZF_DEFAULT_COMMAND "$search '$q_esc'"

    # The helper emits "display<TAB>fullpath". Only field 1 is shown; field 2
    # carries the real path for the preview and the cd.
    #
    # --no-wrap keeps one result per line, so entries stay distinguishable.
    # Long folder paths truncate on the right, which is fine because the
    # filename is leftmost.
    #
    # Both sources answer in well under a second, so re-query on every
    # keystroke rather than filtering a fixed list. Same live pattern as rgf.
    set -l result (
        fzf --ansi \
            --disabled \
            --query "$query" \
            --delimiter '\t' \
            --with-nth 1 \
            --no-wrap \
            --bind "change:reload:$search {q} || true" \
            --bind 'ctrl-/:toggle-preview' \
            --preview "$HOME/.local/share/fzf/preview-path.sh {2}" \
            --preview-window 'up,15%,border-bottom,wrap' \
            --header 'searching all drives + WSL | enter cd\'s there | ctrl-/ toggles preview' \
            --height 90%
    )

    test -n "$result"; or return 0

    set -l path (string split -m 1 \t -- $result)[2]
    test -n "$path"; or return 0

    if test -d "$path"
        cd "$path"
    else
        cd (dirname "$path")
    end
end
