status is-interactive; or exit 0

# Without this, anything that falls back to a default editor (rgf, git commit,
# less, man) picks something else. rgf was defaulting to VS Code.
set -gx EDITOR nvim
set -gx VISUAL nvim
