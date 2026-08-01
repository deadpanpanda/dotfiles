status is-interactive; or exit 0

# fzf 0.74+ installed to ~/.local/bin (ahead of Debian's /usr/bin/fzf on PATH).
# Modern fzf walks directories itself with a built-in Go walker and passes
# --walker-root, rather than eval'ing a command string containing $dir. So the
# old FZF_ALT_C_COMMAND / FZF_CTRL_T_COMMAND approach no longer applies; erase
# them in case an outer shell exported them, since a set-but-empty value also
# tells the integration to skip binding the key entirely.
set -e FZF_ALT_C_COMMAND
set -e FZF_CTRL_T_COMMAND

# Directory names the walker skips. Exact names only, no globs.
set -l fzf_skip '.git,node_modules,__pycache__,.venv,.venv-tts,obj,bin,AppData,.nuget,.cache'

set -l fzf_dir_preview "$HOME/.local/share/fzf/preview-dir.sh {}"
set -l fzf_path_preview "$HOME/.local/share/fzf/preview-path.sh {}"

set -gx FZF_DEFAULT_OPTS "--height 60% --layout=reverse --border --info=inline --wrap"

# No 'follow' in --walker: the Windows home has legacy junctions ("Application
# Data", "Local Settings") pointing back into AppData, and following them turns
# a scan of /mnt/c/Users/adamr from ~2m30s into a rescan of AppData under
# several names.
set -gx FZF_ALT_C_OPTS "--walker=dir,hidden --walker-skip=$fzf_skip --preview '$fzf_dir_preview'"
set -gx FZF_CTRL_T_OPTS "--walker=file,dir,hidden --walker-skip=$fzf_skip --preview '$fzf_path_preview'"

# Must come last: the integration self-invokes fzf_key_bindings, and it reads
# the *_COMMAND variables at that point to decide which keys to bind.
fzf --fish | source
