if status is-interactive
    # Import workspace environment variables from bash
    # Without this, git credentials and workspace tools break in fish
    for line in (bash -c 'source /etc/profile 2>/dev/null; source ~/.bashrc 2>/dev/null; env')
        set -l parts (string split -m 1 '=' -- $line)
        if test (count $parts) -eq 2
            switch $parts[1]
                case PWD SHLVL _ SHELL USER LOGNAME HOME TERM
                    # Skip read-only and shell-managed variables
                    continue
                case '*'
                    set -gx $parts[1] $parts[2]
            end
        end
    end

    starship init fish | source
    zoxide init fish | source
end
