-- Platform helpers.
--
-- This config is a single set of files shared by two Neovim installs:
--   WSL      ~/.config/nvim          -> /mnt/c/repos/dotfiles/nvim
--   Windows  %LOCALAPPDATA%\nvim     -> C:\repos\dotfiles\nvim
--
-- Both are symlinks to the same directory in the dotfiles repo, so anything
-- that hardcodes a path has to work from both sides. `C:\repos\foo` is
-- `/mnt/c/repos/foo` under WSL and the two are the same bytes on disk.

local M = {}

M.is_windows = vim.fn.has("win32") == 1

--- Translate a Windows path to whatever this platform can actually open.
--- On Windows it is returned unchanged; under WSL `C:\x` becomes `/mnt/c/x`.
--- @param path string
--- @return string
function M.from_windows(path)
  if M.is_windows then
    return path
  end
  local drive, rest = path:match("^([A-Za-z]):[\\/](.*)$")
  if not drive then
    return path
  end
  return "/mnt/" .. drive:lower() .. "/" .. rest:gsub("\\", "/")
end

--- Translate a path this platform can open back into a Windows path.
--- Needed whenever a path is handed to a Windows program (UnrealBuildTool,
--- clangd.exe) from the WSL side.
--- @param path string
--- @return string
function M.to_windows(path)
  if M.is_windows then
    return (path:gsub("/", "\\"))
  end
  local drive, rest = path:match("^/mnt/([a-zA-Z])/(.*)$")
  if not drive then
    return path
  end
  return drive:upper() .. ":\\" .. rest:gsub("/", "\\")
end

--- Root of the repos folder on this platform.
--- @param sub string|nil path underneath it, forward slashes
--- @return string
function M.repos(sub)
  local root = M.is_windows and "C:/repos" or "/mnt/c/repos"
  return sub and (root .. "/" .. sub) or root
end

return M
