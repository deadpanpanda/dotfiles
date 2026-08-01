if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    direnv hook fish | source
end
zoxide init fish | source
if not set -q SSH_AGENT_PID
    eval (ssh-agent -c)
end
ssh-add ~/.ssh/id_ed25519 2>/dev/null

set -gx DOTNET_ROOT $HOME/.dotnet
fish_add_path $HOME/.dotnet
