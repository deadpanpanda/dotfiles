status is-interactive; or exit 0

# ripgrep reads its config from this path. The config points at a shared
# ignore list, which ~/.config/fd/ignore symlinks to, so rg and fd filter
# identically.
#
# This matters because several projects here are not git repositories, so
# .gitignore filtering does not apply, and rg would otherwise walk virtualenvs
# and package caches on every search.
set -gx RIPGREP_CONFIG_PATH $HOME/.config/ripgrep/config
