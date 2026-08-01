function rgf --description 'Live ripgrep search across files, pick with fzf, open at the matching line'
    set -l query ''
    set -l dir '.'

    if test (count $argv) -ge 1
        set query $argv[1]
    end
    if test (count $argv) -ge 2
        set dir $argv[2]
    end

    if not test -d "$dir"
        echo "rgf: not a directory: $dir" >&2
        return 1
    end

    if not command -q rg
        echo "rgf: ripgrep (rg) is not installed" >&2
        return 1
    end

    # fzf runs --bind and --preview commands through $SHELL. Force POSIX sh so
    # the snippets below are not parsed as fish.
    set -lx SHELL (command -v sh)

    set -l preview_cmd ~/.local/share/fzf/preview.sh
    set -l rg_cmd "rg --column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git/*'"

    # Escape for embedding in the sh command string below.
    set -l q_esc (string replace -a "'" "'\\''" -- $query)
    set -l d_esc (string replace -a "'" "'\\''" -- $dir)

    set -lx FZF_DEFAULT_COMMAND "$rg_cmd -- '$q_esc' '$d_esc' || true"

    set -l result (
        fzf --ansi \
            --disabled \
            --query "$query" \
            --delimiter : \
            --bind "change:reload:$rg_cmd -- {q} '$d_esc' || true" \
            --bind 'ctrl-/:toggle-preview' \
            --bind "alt-enter:execute-silent($HOME/.local/share/fzf/open-tmux.sh {1} {2})+abort" \
            --preview "$preview_cmd {1} {2} {q}" \
            --preview-window 'up,60%,border-bottom,wrap' \
            --header 'type to search | enter opens here | alt-enter opens a tmux window | ctrl-/ toggles preview' \
            --height 90%
    )

    test -n "$result"; or return 0

    set -l parts (string split -m 3 ':' -- $result)
    set -l file $parts[1]
    set -l line $parts[2]

    set -l ed $EDITOR
    test -n "$ed"; or set ed nvim

    switch (basename $ed)
        case code code-insiders
            $ed --goto "$file:$line"
        case nvim vim vi nano
            $ed "+$line" "$file"
        case '*'
            $ed "$file"
    end
end
